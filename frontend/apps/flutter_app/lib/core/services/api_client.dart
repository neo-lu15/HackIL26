import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) {
    final base = AppConfig.backendBaseUrl.endsWith('/')
        ? AppConfig.backendBaseUrl
            .substring(0, AppConfig.backendBaseUrl.length - 1)
        : AppConfig.backendBaseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalizedPath');
  }

  Map<String, String> _headers({String? token}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> payload, {
    String? token,
  }) async {
    final response = await _client
        .post(
          _uri(path),
          headers: _headers(token: token),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));

    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      throw Exception(
          body['message'] ?? 'Request failed (${response.statusCode})');
    }

    return body;
  }

  Future<Map<String, dynamic>> get(String path, {String? token}) async {
    final response = await _client
        .get(_uri(path), headers: _headers(token: token))
        .timeout(const Duration(seconds: 20));

    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      throw Exception(
          body['message'] ?? 'Request failed (${response.statusCode})');
    }

    return body;
  }
}
