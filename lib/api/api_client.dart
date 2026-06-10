// Thin REST client for the Warehouse Inventory API.
//
// Every response is wrapped in the envelope observed live:
//   { "status": bool, "message": string, "code": int, "data": <payload|null> }
// `request()` validates `status`, unwraps `data`, and throws [ApiException] on
// failure. A 401 transparently triggers a refresh-token retry once.
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_config.dart';
import 'token_store.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic data;
  ApiException(this.statusCode, this.message, [this.data]);
  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404 || message.toLowerCase().contains('not found');
  @override
  String toString() => 'ApiException($statusCode): $message';
}

enum HttpMethod { get, post, patch, delete }

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final http.Client _http = http.Client();
  final TokenStore _tokens = TokenStore.instance;
  Future<bool>? _refreshing;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = AppConfig.apiBaseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    final qp = query?.map((k, v) => MapEntry(k, '$v'));
    return Uri.parse('$base$p').replace(queryParameters: (qp != null && qp.isNotEmpty) ? qp : null);
  }

  Map<String, String> _headers({bool auth = true}) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = _tokens.accessToken;
    if (auth && token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) =>
      request(HttpMethod.get, path, query: query, auth: auth);

  Future<dynamic> post(String path, {Object? body, bool auth = true}) =>
      request(HttpMethod.post, path, body: body, auth: auth);

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) =>
      request(HttpMethod.patch, path, body: body, auth: auth);

  Future<dynamic> delete(String path, {bool auth = true}) =>
      request(HttpMethod.delete, path, auth: auth);

  /// Performs the call, unwraps the envelope, returns `data`. Retries once on 401.
  Future<dynamic> request(
    HttpMethod method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
    bool retried = false,
  }) async {
    final uri = _uri(path, query);
    final headers = _headers(auth: auth);
    final payload = body == null ? null : jsonEncode(body);

    http.Response res;
    try {
      final f = switch (method) {
        HttpMethod.get => _http.get(uri, headers: headers),
        HttpMethod.post => _http.post(uri, headers: headers, body: payload),
        HttpMethod.patch => _http.patch(uri, headers: headers, body: payload),
        HttpMethod.delete => _http.delete(uri, headers: headers, body: payload),
      };
      res = await f.timeout(AppConfig.requestTimeout);
    } on TimeoutException {
      throw ApiException(408, 'Request timed out');
    } catch (e) {
      throw ApiException(0, 'Network error: $e');
    }

    dynamic json;
    if (res.body.isNotEmpty) {
      try {
        json = jsonDecode(res.body);
      } catch (_) {
        // Non-JSON body (e.g. nginx HTML error page).
        throw ApiException(res.statusCode, 'Unexpected response from server');
      }
    }

    // Envelope: {status, message, code, data}
    final bool ok = json is Map && (json['status'] == true);
    final String message = (json is Map ? json['message']?.toString() : null) ?? 'Request failed';
    final int code = (json is Map && json['code'] is int) ? json['code'] as int : res.statusCode;

    final unauthorized = res.statusCode == 401 || code == 401;
    if (unauthorized && auth && !retried) {
      final refreshed = await _ensureRefreshed();
      if (refreshed) {
        return request(method, path, body: body, query: query, auth: auth, retried: true);
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300 && ok) {
      return json['data'];
    }
    throw ApiException(unauthorized ? 401 : code, message, json is Map ? json['data'] : null);
  }

  /// Coalesces concurrent refreshes into a single network call.
  Future<bool> _ensureRefreshed() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final refresh = _tokens.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await _http
          .post(_uri('/auth/refresh'),
              headers: _headers(auth: false), body: jsonEncode({'refreshToken': refresh}))
          .timeout(AppConfig.requestTimeout);
      final json = res.body.isNotEmpty ? jsonDecode(res.body) : null;
      if (json is Map && json['status'] == true && json['data'] != null) {
        final token = _extractAccessToken(json['data']);
        if (token != null) {
          await _tokens.updateAccess(token);
          return true;
        }
      }
    } catch (_) {/* fall through */}
    await _tokens.clear();
    return false;
  }

  /// Tolerant extraction of an access token from a login/refresh payload.
  static String? _extractAccessToken(dynamic data) {
    if (data is! Map) return null;
    for (final k in ['accessToken', 'access_token', 'token', 'jwt']) {
      final v = data[k];
      if (v is String && v.isNotEmpty) return v;
    }
    // Sometimes nested under a `tokens` object.
    if (data['tokens'] is Map) return _extractAccessToken(data['tokens']);
    return null;
  }
}
