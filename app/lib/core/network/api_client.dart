import 'dart:convert';
import 'dart:io';

import 'api_config.dart';
import 'api_exception.dart';
import 'api_session.dart';

class ApiClient {
  ApiClient({
    HttpClient? httpClient,
    this.baseUrl = ApiConfig.baseUrl,
  }) : _httpClient = httpClient ?? HttpClient() {
    _httpClient.connectionTimeout = ApiConfig.connectTimeout;
  }

  final HttpClient _httpClient;
  final String baseUrl;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      path: _joinPath(path),
      queryParameters: _toQueryParams(query),
    );
    final request = await _httpClient.getUrl(uri).timeout(ApiConfig.connectTimeout);
    _addDefaultHeaders(request);
    _addHeaders(request, headers);
    final response = await request.close().timeout(ApiConfig.readTimeout);
    final body = await response.transform(utf8.decoder).join();
    _throwIfNotOk(response.statusCode, body);
    return _decodeToMap(body);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      path: _joinPath(path),
      queryParameters: _toQueryParams(query),
    );
    final request = await _httpClient.postUrl(uri).timeout(ApiConfig.connectTimeout);
    request.headers.set(HttpHeaders.contentTypeHeader, ContentType.json.value);
    _addDefaultHeaders(request);
    _addHeaders(request, headers);
    request.write(jsonEncode(body));
    final response = await request.close().timeout(ApiConfig.readTimeout);
    final responseBody = await response.transform(utf8.decoder).join();
    _throwIfNotOk(response.statusCode, responseBody);
    return _decodeToMap(responseBody);
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      path: _joinPath(path),
      queryParameters: _toQueryParams(query),
    );
    final request = await _httpClient.putUrl(uri).timeout(ApiConfig.connectTimeout);
    request.headers.set(HttpHeaders.contentTypeHeader, ContentType.json.value);
    _addDefaultHeaders(request);
    _addHeaders(request, headers);
    request.write(jsonEncode(body));
    final response = await request.close().timeout(ApiConfig.readTimeout);
    final responseBody = await response.transform(utf8.decoder).join();
    _throwIfNotOk(response.statusCode, responseBody);
    return _decodeToMap(responseBody);
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      path: _joinPath(path),
      queryParameters: _toQueryParams(query),
    );
    final request = await _httpClient.deleteUrl(uri).timeout(ApiConfig.connectTimeout);
    _addDefaultHeaders(request);
    _addHeaders(request, headers);
    final response = await request.close().timeout(ApiConfig.readTimeout);
    final responseBody = await response.transform(utf8.decoder).join();
    _throwIfNotOk(response.statusCode, responseBody);
    if (responseBody.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }

  Future<List<dynamic>> getJsonList(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      path: _joinPath(path),
      queryParameters: _toQueryParams(query),
    );
    final request = await _httpClient.getUrl(uri).timeout(ApiConfig.connectTimeout);
    _addDefaultHeaders(request);
    _addHeaders(request, headers);
    final response = await request.close().timeout(ApiConfig.readTimeout);
    final body = await response.transform(utf8.decoder).join();
    _throwIfNotOk(response.statusCode, body);
    final jsonData = jsonDecode(body);
    if (jsonData is List<dynamic>) return jsonData;
    if (jsonData is Map<String, dynamic>) {
      final extracted = _extractWrappedList(jsonData);
      if (extracted != null) return extracted;
    }
    throw ApiException('Expected a JSON array response', statusCode: response.statusCode, body: body);
  }

  List<dynamic>? _extractWrappedList(Map<String, dynamic> json) {
    final directKeys = ['data', 'items', 'results', 'messages'];
    for (final key in directKeys) {
      final value = json[key];
      if (value is List<dynamic>) return value;
    }

    final nestedData = json['data'];
    if (nestedData is Map<String, dynamic>) {
      for (final key in ['rows', 'items', 'results']) {
        final value = nestedData[key];
        if (value is List<dynamic>) return value;
      }
    }
    return null;
  }

  String _joinPath(String path) {
    final normalizedBase = Uri.parse(baseUrl).path;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    if (normalizedBase.isEmpty || normalizedBase == '/') return '/$cleanPath';
    final base = normalizedBase.endsWith('/') ? normalizedBase.substring(0, normalizedBase.length - 1) : normalizedBase;
    return '$base/$cleanPath';
  }

  Map<String, String>? _toQueryParams(Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return null;
    return query.map((key, value) => MapEntry(key, '$value'));
  }

  void _addDefaultHeaders(HttpClientRequest request) {
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.value);
    final token = ApiSession.bearerToken;
    if (token != null && token.isNotEmpty) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
  }

  void _addHeaders(HttpClientRequest request, Map<String, String>? headers) {
    if (headers == null) return;
    for (final entry in headers.entries) {
      request.headers.set(entry.key, entry.value);
    }
  }

  void _throwIfNotOk(int statusCode, String body) {
    if (statusCode >= 200 && statusCode < 300) return;
    throw ApiException('Request failed with status $statusCode', statusCode: statusCode, body: body);
  }

  Map<String, dynamic> _decodeToMap(String body) {
    final jsonData = jsonDecode(body);
    if (jsonData is Map<String, dynamic>) return jsonData;
    throw ApiException('Expected a JSON object response', body: body);
  }
}
