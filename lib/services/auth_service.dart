// lib/services/auth_service.dart
// ─────────────────────────────────
// Accounts live on the SERVER (full name + mobile number + 4-digit PIN), so
// the same number and PIN work on any phone. After sign-in the phone keeps
// the mobile number, name and a token so the farmer stays signed in.
//
// Every piece of per-user data stored on the phone (offline queue, ...) must
// use `AuthService.instance.scopedKey('your_key')`.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _mobileKey = 'auth_current_mobile';
  static const _nameKey   = 'auth_current_name';
  static const _tokenKey  = 'auth_current_token';

  // Modal may need a moment to wake up on the first request.
  static const _timeout = Duration(seconds: 120);

  /// Holds the signed-in mobile number (null = signed out).
  final ValueNotifier<String?> userNotifier = ValueNotifier<String?>(null);

  String? _displayName;
  String? _token;

  String? get currentUser => userNotifier.value;   // mobile number
  String? get displayName => _displayName;         // farmer's full name
  String? get token       => _token;               // sent with every request
  bool get isLoggedIn => currentUser != null;

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
      _displayName = name;
      _token = token;
      userNotifier.value = mobile;
    }
  }

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

    final data = await _post('/api/v1/auth/register',
        {'name': cleanName, 'mobile': number, 'pin': pin});
    await _saveSession(data);
  }

  Future<void> login({required String mobile, required String pin}) async {
    final number = normalizeMobile(mobile);
    if (number == null) {
      throw const AuthException('Enter a valid mobile number.');
    }
    final data = await _post('/api/v1/auth/login',
        {'mobile': number, 'pin': pin});
    await _saveSession(data);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mobileKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_tokenKey);
    _displayName = null;
    _token = null;
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

  Future<Map<String, dynamic>> _post(String path, Map<String, String> body) async {
    final http.Response res;
    try {
      res = await http
          .post(
        Uri.parse('${ApiService.baseUrl}$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      )
          .timeout(_timeout);
    } catch (e) {
      debugPrint('Auth request failed: $e');
      throw const AuthException(
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
        (json['message'] as String?) ?? 'Something went wrong. Please try again.');
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final mobile = data['mobile'] as String;
    final name   = data['name'] as String;
    final token  = data['token'] as String;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mobileKey, mobile);
    await prefs.setString(_nameKey, name);
    await prefs.setString(_tokenKey, token);

    _displayName = name;
    _token = token;
    userNotifier.value = mobile;
  }
}