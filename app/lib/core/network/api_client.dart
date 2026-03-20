import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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

  static void _log(String method, String url, {String? requestBody, int? statusCode, String? responseBody}) {
    debugPrint('═══ API $method $url');
    if (requestBody != null) debugPrint('  REQ: $requestBody');
    if (statusCode != null) debugPrint('  RES: $statusCode');
    if (responseBody != null) {
      final truncated = responseBody.length > 500 ? '${responseBody.substring(0, 500)}...' : responseBody;
      debugPrint('  BODY: $truncated');
    }
    debugPrint('══════════════════════════════════════');
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      path: _joinPath(path),
      queryParameters: _toQueryParams(query),
    );
    final url = uri.toString();
    try {
      final request = await _httpClient.getUrl(uri).timeout(ApiConfig.connectTimeout);
      _addDefaultHeaders(request);
      _addHeaders(request, headers);
      final response = await request.close().timeout(ApiConfig.readTimeout);
      final body = await response.transform(utf8.decoder).join();
      _log('GET', url, statusCode: response.statusCode, responseBody: body);
      if (response.statusCode == 401 && ApiSession.refreshToken != null && !path.contains('/auth/refresh')) {
        final refreshed = await _tryRefreshTokens();
        if (refreshed) return await getJson(path, headers: headers, query: query);
      }
      _throwIfNotOk(response.statusCode, body);
      return _decodeToMap(body);
    } catch (e) {
      _log('GET', url, responseBody: e.toString());
      rethrow;
    }
  }

  static const _imageMimeTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'heic': 'image/heic',
    'heif': 'image/heif',
  };

  Future<Map<String, dynamic>> postMultipartFile(
    String apiPath,
    File file, {
    String fieldName = 'image',
  }) async {
    final path = _joinPath(apiPath);
    final uri = Uri.parse(baseUrl).replace(path: path);
    final request = http.MultipartRequest('POST', uri);
    request.headers['Accept'] = 'application/json';
    if (ApiSession.bearerToken != null && ApiSession.bearerToken!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer ${ApiSession.bearerToken}';
    }
    final ext = file.path.split('.').last.toLowerCase();
    final mimeType = _imageMimeTypes[ext] ?? 'image/jpeg';
    request.files.add(await http.MultipartFile.fromPath(
      fieldName,
      file.path,
      contentType: MediaType.parse(mimeType),
    ));
    final streamedResponse = await request.send().timeout(ApiConfig.readTimeout);
    final responseBody = await streamedResponse.stream.transform(utf8.decoder).join();
    if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
      _throwIfNotOk(streamedResponse.statusCode, responseBody);
    }
    return _decodeToMap(responseBody);
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
    final url = uri.toString();
    final bodyEncoded = jsonEncode(body);
    final request = await _httpClient.postUrl(uri).timeout(ApiConfig.connectTimeout);
    request.headers.set(HttpHeaders.contentTypeHeader, ContentType.json.value);
    _addDefaultHeaders(request);
    _addHeaders(request, headers);
    request.write(bodyEncoded);
    final response = await request.close().timeout(ApiConfig.readTimeout);
    final responseBody = await response.transform(utf8.decoder).join();
    _log('POST', url, requestBody: bodyEncoded, statusCode: response.statusCode, responseBody: responseBody);
    if (response.statusCode == 401 && ApiSession.refreshToken != null && !path.contains('/auth/refresh')) {
      final refreshed = await _tryRefreshTokens();
      if (refreshed) return await postJson(path, body: body, headers: headers, query: query);
    }
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
    final url = uri.toString();
    final bodyStr = jsonEncode(body);
    try {
      final request = await _httpClient.putUrl(uri).timeout(ApiConfig.connectTimeout);
      request.headers.set(HttpHeaders.contentTypeHeader, ContentType.json.value);
      _addDefaultHeaders(request);
      _addHeaders(request, headers);
      request.write(bodyStr);
      final response = await request.close().timeout(ApiConfig.readTimeout);
      final responseBody = await response.transform(utf8.decoder).join();
      _log('PUT', url, requestBody: bodyStr, statusCode: response.statusCode, responseBody: responseBody);
      if (response.statusCode == 401 && ApiSession.refreshToken != null && !path.contains('/auth/refresh')) {
        final refreshed = await _tryRefreshTokens();
        if (refreshed) return await putJson(path, body: body, headers: headers, query: query);
      }
      _throwIfNotOk(response.statusCode, responseBody);
      return _decodeToMap(responseBody);
    } catch (e) {
      _log('PUT', url, requestBody: bodyStr, responseBody: e.toString());
      rethrow;
    }
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
    final url = uri.toString();
    try {
      final request = await _httpClient.deleteUrl(uri).timeout(ApiConfig.connectTimeout);
      _addDefaultHeaders(request);
      _addHeaders(request, headers);
      final response = await request.close().timeout(ApiConfig.readTimeout);
      final responseBody = await response.transform(utf8.decoder).join();
      _log('DELETE', url, statusCode: response.statusCode, responseBody: responseBody);
      if (response.statusCode == 401 && ApiSession.refreshToken != null && !path.contains('/auth/refresh')) {
        final refreshed = await _tryRefreshTokens();
        if (refreshed) return await deleteJson(path, headers: headers, query: query);
      }
      _throwIfNotOk(response.statusCode, responseBody);
      if (responseBody.trim().isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{};
    } catch (e) {
      _log('DELETE', url, responseBody: e.toString());
      rethrow;
    }
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
    final url = uri.toString();
    try {
      final request = await _httpClient.getUrl(uri).timeout(ApiConfig.connectTimeout);
      _addDefaultHeaders(request);
      _addHeaders(request, headers);
      final response = await request.close().timeout(ApiConfig.readTimeout);
      final body = await response.transform(utf8.decoder).join();
      _log('GET', url, statusCode: response.statusCode, responseBody: body);
      if (response.statusCode == 401 && ApiSession.refreshToken != null && !path.contains('/auth/refresh')) {
        final refreshed = await _tryRefreshTokens();
        if (refreshed) return await getJsonList(path, headers: headers, query: query);
      }
      _throwIfNotOk(response.statusCode, body);
      final jsonData = jsonDecode(body);
      if (jsonData is List<dynamic>) return jsonData;
      if (jsonData is Map<String, dynamic>) {
        final extracted = _extractWrappedList(jsonData);
        if (extracted != null) return extracted;
      }
      throw ApiException('Expected a JSON array response', statusCode: response.statusCode, body: body);
    } catch (e) {
      _log('GET', url, responseBody: e.toString());
      rethrow;
    }
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

  /// Try to refresh tokens. Returns true if successful.
  Future<bool> _tryRefreshTokens() async {
    final rt = ApiSession.refreshToken;
    if (rt == null || rt.isEmpty) return false;
    try {
      final uri = Uri.parse(baseUrl).replace(path: _joinPath('/auth/refresh'));
      final request = await _httpClient.postUrl(uri).timeout(ApiConfig.connectTimeout);
      request.headers.set(HttpHeaders.contentTypeHeader, ContentType.json.value);
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.value);
      request.write(jsonEncode({'refreshToken': rt}));
      final response = await request.close().timeout(ApiConfig.readTimeout);
      final responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(responseBody) as Map<String, dynamic>?;
        final tokens = json?['tokens'];
        if (tokens is Map<String, dynamic>) {
          final accessToken = '${tokens['accessToken'] ?? ''}';
          final newRefresh = '${tokens['refreshToken'] ?? ''}';
          if (accessToken.isNotEmpty) {
            ApiSession.setSession(
              token: accessToken,
              refreshToken: newRefresh.isEmpty ? null : newRefresh,
              userId: ApiSession.currentUserId,
            );
            return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  void _throwIfNotOk(int statusCode, String body) {
    if (statusCode >= 200 && statusCode < 300) return;

    // Clear session when token is invalid/expired (only if we didn't just refresh)
    final isAuthFailure = statusCode == 401 ||
        (statusCode == 403 && (body.contains('expired') || (body.contains('Invalid') && body.contains('token'))));
    if (isAuthFailure) {
      ApiSession.clear();
    }

    throw ApiException('Request failed with status $statusCode', statusCode: statusCode, body: body);
  }

  Map<String, dynamic> _decodeToMap(String body) {
    final jsonData = jsonDecode(body);
    if (jsonData is Map<String, dynamic>) return jsonData;
    throw ApiException('Expected a JSON object response', body: body);
  }
}
