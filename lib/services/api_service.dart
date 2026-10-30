import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/analysis_result.dart';
import '../models/history_response.dart';
import 'auth_service.dart';

class ApiService {

  static const String baseUrl = 'https://mybackendricepest-production.up.railway.app';

  static const Duration _timeout = Duration(seconds: 120);

  /// Global notifier triggered whenever history items are created or deleted.
  static final ValueNotifier<int> historyUpdateNotifier = ValueNotifier<int>(0);

  static void notifyHistoryChanged() {
    historyUpdateNotifier.value++;
  }


  ApiService._internal();
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;


  Future<Map<String, String>> _headers() async {
    try {
      await AuthService.instance.ensureSynced();
    } on NetworkAuthException {

      throw const SocketException('No internet connection');
    } on AuthException catch (e) {
      throw ApiException(e.message, statusCode: e.statusCode);
    }

    final userId = AuthService.instance.currentUser;
    final token  = AuthService.instance.token;
    if (userId == null || token == null || token.isEmpty) {
      throw const ApiException('Please sign in first.', statusCode: 401);
    }
    return {'X-User-Id': userId, 'X-Auth-Token': token};
  }

  Future<bool> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/'))
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }


  /// Upload [imageFile] and return an [AnalysisResult].
  Future<AnalysisResult> analyzeImage(File imageFile) async {
    final uri     = Uri.parse('$baseUrl/api/v1/analyze');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(await _headers());

    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final streamedResponse = await request.send().timeout(_timeout);
    final response         = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return AnalysisResult.fromJson(json['data'] as Map<String, dynamic>);
      }
      throw ApiException(json['message'] ?? 'Unknown error');
    }

    _handleError(response);
    throw ApiException('Unexpected error (${response.statusCode})');
  }


  static Future<Set<int>> getDeletedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = AuthService.instance.scopedKey('deleted_history_ids');
      final list = prefs.getStringList(key) ?? [];
      return list.map((e) => int.tryParse(e)).whereType<int>().toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> markAsDeleted(List<int> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = AuthService.instance.scopedKey('deleted_history_ids');
      final current = (prefs.getStringList(key) ?? []).toSet();
      for (final id in ids) {
        current.add(id.toString());
      }
      await prefs.setStringList(key, current.toList());
    } catch (_) {}
  }

  Future<HistoryResponse> getHistory({int page = 1, int perPage = 20}) async {
    final uri = Uri.parse(
      '$baseUrl/api/v1/history?page=$page&per_page=$perPage',
    );
    final response =
    await http.get(uri, headers: await _headers()).timeout(_timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final fullResponse = HistoryResponse.fromJson(json['data'] as Map<String, dynamic>);

      final deletedSet = await getDeletedIds();
      if (deletedSet.isNotEmpty) {
        final filteredRecords = fullResponse.records
            .where((r) => r.id == null || !deletedSet.contains(r.id))
            .toList();
        final newTotal = fullResponse.total - deletedSet.length > 0
            ? fullResponse.total - deletedSet.length
            : filteredRecords.length;
        return HistoryResponse(
          records: filteredRecords,
          total: newTotal,
          page: fullResponse.page,
          perPage: fullResponse.perPage,
          pages: fullResponse.pages,
        );
      }

      return fullResponse;
    }
    _handleError(response);
    throw ApiException('Failed to fetch history (${response.statusCode})');
  }


  Future<AnalysisResult> getAnalysisById(int id) async {
    final uri      = Uri.parse('$baseUrl/api/v1/history/$id');
    final response =
    await http.get(uri, headers: await _headers()).timeout(_timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AnalysisResult.fromJson(json['data'] as Map<String, dynamic>);
    }
    _handleError(response);
    throw ApiException('Failed to fetch analysis #$id (${response.statusCode})');
  }


  Future<void> deleteAnalysis(int id) async {
    await markAsDeleted([id]);
    try {
      final uri = Uri.parse('$baseUrl/api/v1/history/$id');
      final response =
      await http.delete(uri, headers: await _headers()).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }

      // Fallback if backend server requires POST method for delete
      if (response.statusCode == 405) {
        final postUri = Uri.parse('$baseUrl/api/v1/history/$id/delete');
        final postResp =
        await http.post(postUri, headers: await _headers()).timeout(_timeout);
        if (postResp.statusCode == 200 || postResp.statusCode == 204) {
          return;
        }
      }
    } catch (_) {
      // Local deletion is saved persistently via SharedPreferences
    }
  }

  Future<void> deleteMultipleAnalyses(List<int> ids) async {
    await markAsDeleted(ids);
    for (final id in ids) {
      await deleteAnalysis(id);
    }
  }


  Future<Map<String, dynamic>> getStats() async {
    final uri      = Uri.parse('$baseUrl/api/v1/stats');
    final response =
    await http.get(uri, headers: await _headers()).timeout(_timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['data'] as Map<String, dynamic>;
    }
    _handleError(response);
    throw ApiException('Failed to fetch stats (${response.statusCode})');
  }


  void _handleError(http.Response response) {
    String message = 'An error occurred (${response.statusCode})';
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      message = json['message'] as String? ?? message;
    } catch (_) {}
    throw ApiException(message, statusCode: response.statusCode);
  }
}


class ApiException implements Exception {
  final String message;
  final int?   statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (HTTP $statusCode)';
}