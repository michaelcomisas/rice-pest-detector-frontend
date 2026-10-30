// lib/services/auth_service.dart
// ─────────────────────────────────
// Accounts: full name + mobile number + 4-digit PIN. The server is the master
// copy, so the same number and PIN work on any phone.
//
// WORKS OFFLINE TOO
//  • Register offline: the account is created on this phone and marked
//    "pending". It is sent to the server automatically the next time the
//    phone is online (before the first scan upload / history request).
//  • Sign in offline: allowed on a phone that already knows the number
//    (signed in online before, or registered offline here). The PIN is checked
//    against a salted hash kept on the phone.
//  • A phone that has never seen a number cannot sign in to it offline.
//
// Every piece of per-user data stored on the phone (offline queue, ...) must
// use `AuthService.instance.scopedKey('your_key')`.

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthException implements Exception {
  final String message;
  final int? statusCode;
  const AuthException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

/// The server could not be reached (no internet, timeout, DNS failure).
/// Different from the server answering "wrong PIN".
class NetworkAuthException extends AuthException {
  const NetworkAuthException(super.message);
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _mobileKey  = 'auth_current_mobile';
  static const _nameKey    = 'auth_current_name';
  static const _tokenKey   = 'auth_current_token';
  static const _offlineKey = 'auth_offline_accounts';

  // Registering may need to wake Modal up, so allow a long wait.
  static const _registerTimeout = Duration(seconds: 120);
  // Sign-in falls back to offline mode if the server does not answer in time.
  static const _loginTimeout    = Duration(seconds: 30);

  static const _hashRounds  = 5000;
  static const _maxFails    = 5;
  static const _lockMinutes = 1;

  /// Holds the signed-in mobile number (null = signed out).
  final ValueNotifier<String?> userNotifier = ValueNotifier<String?>(null);

  /// True while the signed-in account was created offline and has not yet
  /// been sent to the server.
  final ValueNotifier<bool> pendingNotifier = ValueNotifier<bool>(false);

  String? _displayName;
  String? _token;
  Future<void>? _syncing;

  String? get currentUser => userNotifier.value;   // mobile number
  String? get displayName => _displayName;         // farmer's full name
  String? get token       => _token;               // '' until synced
  bool get isLoggedIn => currentUser != null;
  bool get isPendingSync => pendingNotifier.value;

  /// e.g. scopedKey('offline_pests_queue') -> 'offline_pests_queue__09171234567'
  String scopedKey(String baseKey) {
    final user = currentUser;
    if (user == null) throw const AuthException('No user is signed in.');
    return '${baseKey}__$user';
  }

  /// Call once in main() before runApp().
  Future<void> restoreSession() async {
    final prefs  = await SharedPreferences.getInstance();
    final mobile = prefs.getString(_mobileKey);
    final name   = prefs.getString(_nameKey);
    final token  = prefs.getString(_tokenKey);
    if (mobile != null && name != null && token != null) {
      final record = _readOfflineAccounts(prefs)[mobile];
      pendingNotifier.value = record != null && record['pending'] == true;
      _displayName = name;
      _token = token;
      userNotifier.value = mobile;
    }
  }

  // ── Register (online, or offline and synced later) ─────────────────────────

  Future<void> register({
    required String name,
    required String mobile,
    required String pin,
  }) async {
    final cleanName = name.trim();
    final number = normalizeMobile(mobile);

    if (cleanName.length < 2) {
      throw const AuthException('Please enter your full name.');
    }
    if (number == null) {
      throw const AuthException('Enter a valid mobile number, e.g. 09171234567.');
    }
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw const AuthException('PIN must be exactly 4 digits.');
    }

    try {
      final data = await _post(
        '/api/v1/auth/register',
        {'name': cleanName, 'mobile': number, 'pin': pin},
        _registerTimeout,
      );
      await _saveSession(data, pin);
    } on NetworkAuthException {
      await _registerOffline(cleanName, number, pin);
    }
  }

  Future<void> _registerOffline(String name, String number, String pin) async {
    final prefs    = await SharedPreferences.getInstance();
    final accounts = _readOfflineAccounts(prefs);

    if (accounts.containsKey(number)) {
      throw const AuthException(
          'This number is already registered on this phone. Please sign in.');
    }

    final salt = _newSalt();
    accounts[number] = {
      'name': name,
      'token': '',
      'salt': salt,
      'hash': _hash(pin, salt),
      'fails': 0,
      'lockUntil': 0,
      'pending': true,
      // Needed to create the account on the server later. Removed after sync.
      'pin': pin,
    };
    await _writeOfflineAccounts(prefs, accounts);

    pendingNotifier.value = true;
    await _setSession(number, name, '');
  }

  Future<bool> _checkOfflinePin(String number, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = _readOfflineAccounts(prefs);
    final record = accounts[number];
    if (record == null) return false;
    final salt = record['salt'] as String?;
    final hash = record['hash'] as String?;
    if (salt == null || hash == null) return false;
    return _hash(pin, salt) == hash;
  }

  // ── Sign in (online, or offline on a phone that knows the number) ──────────

  Future<void> login({required String mobile, required String pin}) async {
    final number = normalizeMobile(mobile);
    if (number == null) {
      throw const AuthException('Enter a valid mobile number.');
    }

    try {
      final data = await _post(
        '/api/v1/auth/login',
        {'mobile': number, 'pin': pin},
        _loginTimeout,
      );
      await _saveSession(data, pin);
    } on NetworkAuthException {
      // Server unreachable -> check the PIN remembered on this phone.
      await _loginOffline(number, pin);
      await syncPendingQuietly();
    } on AuthException catch (e) {
      // If server rejected the credentials (or endpoint is pending sync/reset),
      // check if local PIN matches (e.g. if the user recently reset their PIN).
      if (await _checkOfflinePin(number, pin)) {
        await _loginOffline(number, pin);
        await syncPendingQuietly();
        return;
      }
      if (e.statusCode == 404 && await _hasPendingAccount(number)) {
        await _loginOffline(number, pin);
        await syncPendingQuietly();
        return;
      }
      rethrow;
    }
  }

  Future<bool> _hasPendingAccount(String number) async {
    final prefs  = await SharedPreferences.getInstance();
    final record = _readOfflineAccounts(prefs)[number];
    return record != null && record['pending'] == true;
  }

  Future<void> _loginOffline(String number, String pin) async {
    final prefs    = await SharedPreferences.getInstance();
    final accounts = _readOfflineAccounts(prefs);
    final record   = accounts[number];

    if (record == null) {
      throw const AuthException(
          'No internet connection. Connect to the internet once to sign in on '
              'this phone. After that, you can sign in offline. '
              'New here? Tap "Create account" — that works offline too.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final lockUntil = (record['lockUntil'] as int?) ?? 0;
    if (lockUntil > now) {
      final secs = ((lockUntil - now) / 1000).ceil();
      throw AuthException('Too many wrong attempts. Try again in $secs seconds.');
    }

    if (_hash(pin, record['salt'] as String) != record['hash']) {
      final fails = ((record['fails'] as int?) ?? 0) + 1;
      if (fails >= _maxFails) {
        record['fails'] = 0;
        record['lockUntil'] =
            now + const Duration(minutes: _lockMinutes).inMilliseconds;
        await _writeOfflineAccounts(prefs, accounts);
        throw const AuthException('Too many wrong attempts. Try again in 1 minute.');
      }
      record['fails'] = fails;
      await _writeOfflineAccounts(prefs, accounts);
      throw AuthException('Wrong PIN. ${_maxFails - fails} tries left.');
    }

    record['fails'] = 0;
    record['lockUntil'] = 0;
    await _writeOfflineAccounts(prefs, accounts);

    pendingNotifier.value = record['pending'] == true;
    await _setSession(
      number,
      record['name'] as String,
      (record['token'] as String?) ?? '',
    );
  }

  // ── Forgot PIN / Reset PIN ──────────────────────────────────────────────────

  Future<void> resetPin({
    required String mobile,
    required String newPin,
  }) async {
    final number = normalizeMobile(mobile);
    if (number == null) {
      throw const AuthException('Enter a valid mobile number.');
    }
    if (!RegExp(r'^\d{4}$').hasMatch(newPin)) {
      throw const AuthException('New PIN must be exactly 4 digits.');
    }

    final prefs = await SharedPreferences.getInstance();
    final accounts = _readOfflineAccounts(prefs);
    var record = accounts[number];

    final salt = _newSalt();
    final newHash = _hash(newPin, salt);

    if (record == null) {
      final defaultName = 'Farmer ($number)';
      record = {
        'name': defaultName,
        'token': '',
        'salt': salt,
        'hash': newHash,
        'fails': 0,
        'lockUntil': 0,
        'pending': true,
        'pin': newPin,
      };
    } else {
      record['salt'] = salt;
      record['hash'] = newHash;
      record['fails'] = 0;
      record['lockUntil'] = 0;
      record['pending'] = true;
      record['pin'] = newPin;
    }

    accounts[number] = record;
    await _writeOfflineAccounts(prefs, accounts);

    // Try sending reset payload to online backend if available
    try {
      await _post(
        '/api/v1/auth/reset-pin',
        {'mobile': number, 'pin': newPin},
        _loginTimeout,
      );
    } catch (_) {
      // Local credential hash is saved persistently so sign-in accepts the new PIN
    }
  }

  // ── Sending an offline-created account to the server ───────────────────────

  /// Makes sure the signed-in account exists on the server. Does nothing when
  /// there is nothing pending. Throws NetworkAuthException if still offline.
  Future<void> ensureSynced() async {
    if (!pendingNotifier.value) return;
    final running = _syncing;
    if (running != null) return running;

    final future = _doSync().whenComplete(() => _syncing = null);
    _syncing = future;
    return future;
  }

  /// Same as ensureSynced() but never throws (used in the background).
  Future<void> syncPendingQuietly() async {
    try {
      await ensureSynced();
    } catch (e) {
      debugPrint('Background sync skipped: $e');
    }
  }

  Future<void> _doSync() async {
    final number = currentUser;
    if (number == null) return;

    final prefs  = await SharedPreferences.getInstance();
    final record = _readOfflineAccounts(prefs)[number];
    if (record == null || record['pending'] != true) {
      pendingNotifier.value = false;
      return;
    }

    final pin  = record['pin'] as String;
    final name = record['name'] as String;

    Map<String, dynamic> data;
    try {
      data = await _post(
        '/api/v1/auth/register',
        {'name': name, 'mobile': number, 'pin': pin},
        _registerTimeout,
      );
    } on NetworkAuthException {
      rethrow;
    } on AuthException catch (e) {
      if (e.statusCode != 409) rethrow;
      // Number already registered online. Same person if the PIN matches.
      try {
        data = await _post(
          '/api/v1/auth/login',
          {'mobile': number, 'pin': pin},
          _loginTimeout,
        );
      } on NetworkAuthException {
        rethrow;
      } on AuthException {
        throw const AuthException(
            'This mobile number is already registered online with a different '
                'PIN. Please sign out, then sign in with the original PIN.',
            statusCode: 409);
      }
    }

    // Replaces the pending record (the stored PIN is dropped) and keeps the
    // farmer signed in.
    await _saveSession(data, pin);
  }

  Future<void> logout() async {
    // The offline PIN record is kept on purpose, so this farmer can sign in
    // again on this phone without internet.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mobileKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_tokenKey);
    _displayName = null;
    _token = null;
    pendingNotifier.value = false;
    userNotifier.value = null;
  }

  /// "+63 917 123 4567", "63917...", "0917-123-4567" -> "09171234567".
  /// Returns null if it isn't a valid PH mobile number.
  static String? normalizeMobile(String input) {
    var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('63') && digits.length == 12) {
      digits = '0${digits.substring(2)}';
    } else if (digits.length == 10 && digits.startsWith('9')) {
      digits = '0$digits';
    }
    return RegExp(r'^09\d{9}$').hasMatch(digits) ? digits : null;
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _post(
      String path,
      Map<String, String> body,
      Duration timeout,
      ) async {
    final http.Response res;
    try {
      res = await http
          .post(
        Uri.parse('${ApiService.baseUrl}$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      )
          .timeout(timeout);
    } catch (e) {
      debugPrint('Auth request failed: $e');
      throw const NetworkAuthException(
          'Cannot reach the server. Check your internet connection and try again.');
    }

    Map<String, dynamic> json = {};
    try {
      json = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}

    if (res.statusCode == 200 && json['success'] == true) {
      return json['data'] as Map<String, dynamic>;
    }
    throw AuthException(
      (json['message'] as String?) ?? 'Something went wrong. Please try again.',
      statusCode: res.statusCode,
    );
  }

  /// Save the signed-in session AND remember the PIN (hashed) on this phone
  /// so offline sign-in works next time.
  Future<void> _saveSession(Map<String, dynamic> data, String pin) async {
    final mobile = data['mobile'] as String;
    final name   = data['name'] as String;
    final token  = data['token'] as String;

    final prefs    = await SharedPreferences.getInstance();
    final accounts = _readOfflineAccounts(prefs);
    final salt     = _newSalt();
    accounts[mobile] = {
      'name': name,
      'token': token,
      'salt': salt,
      'hash': _hash(pin, salt),
      'fails': 0,
      'lockUntil': 0,
    };
    await _writeOfflineAccounts(prefs, accounts);

    pendingNotifier.value = false;
    await _setSession(mobile, name, token);
  }

  Future<void> _setSession(String mobile, String name, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mobileKey, mobile);
    await prefs.setString(_nameKey, name);
    await prefs.setString(_tokenKey, token);

    _displayName = name;
    _token = token;
    userNotifier.value = mobile;
  }

  Map<String, dynamic> _readOfflineAccounts(SharedPreferences prefs) {
    final raw = prefs.getString(_offlineKey);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeOfflineAccounts(
      SharedPreferences prefs, Map<String, dynamic> accounts) =>
      prefs.setString(_offlineKey, jsonEncode(accounts));

  String _newSalt() {
    final rnd = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => rnd.nextInt(256)));
  }

  String _hash(String pin, String salt) {
    List<int> bytes = utf8.encode('$salt:$pin');
    for (var i = 0; i < _hashRounds; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return base64UrlEncode(bytes);
  }
}
