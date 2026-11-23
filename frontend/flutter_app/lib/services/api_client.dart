import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic> body;

  const ApiException(this.message, {this.statusCode, this.body = const {}});

  /// True when the session is missing or expired. flask-jwt-extended answers a
  /// malformed token with a 422 whose body has a "msg" field.
  bool get isUnauthorized => statusCode == 401 || (statusCode == 422 && body.containsKey('msg'));

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// The one place that talks HTTP. It handles the base URL, the auth header, timeouts and errors.
class ApiClient {
  ApiClient({http.Client? httpClient, required this.tokens, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _http;
  final String _baseUrl;
  final TokenStorage tokens;

  Future<Map<String, dynamic>> get(String path, {bool auth = false}) => _send('GET', path, auth: auth);

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {bool auth = false}) =>
      _send('POST', path, body: body, auth: auth);

  Future<Map<String, dynamic>> _send(String method, String path,
      {Map<String, dynamic>? body, required bool auth}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await tokens.readToken();
      if (token == null) throw const ApiException('Please log in again.', statusCode: 401);
      headers['Authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse('$_baseUrl$path');
    http.Response res;
    try {
      final request = method == 'GET'
          ? _http.get(uri, headers: headers)
          : _http.post(uri, headers: headers, body: jsonEncode(body ?? const {}));
      res = await request.timeout(AppConfig.requestTimeout);
    } on TimeoutException {
      throw const ApiException('The server is taking too long. Please try again.');
    } catch (_) {
      throw const ApiException('Network error. Please check your connection and try again.');
    }

    Map<String, dynamic> data;
    try {
      final decoded = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body);
      data = decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    } on FormatException {
      data = {};
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    final message = (data['message'] ?? data['msg'] ?? 'Something went wrong (${res.statusCode}).') as String;
    throw ApiException(message, statusCode: res.statusCode, body: data);
  }
}
