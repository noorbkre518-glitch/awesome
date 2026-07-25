import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, SocketException;

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:http/http.dart' as http;

import '../storage/server_url_storage.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
    TokenStorage? tokenStorage,
    ServerUrlStorage? serverUrlStorage,
  })  : baseUrl = _normalize(baseUrl ?? _defaultBase()),
        _client = httpClient ?? http.Client(),
        _tokenStorage = tokenStorage ?? SecureTokenStorage(),
        _serverUrlStorage = serverUrlStorage ?? PreferencesServerUrlStorage();

  String baseUrl;
  final http.Client _client;
  final TokenStorage _tokenStorage;
  final ServerUrlStorage _serverUrlStorage;
  String? _token;
  bool _handlingUnauthorized = false;

  FutureOr<void> Function()? onUnauthorized;

  static const Duration _timeout = Duration(seconds: 15);

  static String _defaultBase() {
    const fromEnv = String.fromEnvironment('API_BASE');
    if (fromEnv.isNotEmpty) return fromEnv;
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    } catch (_) {}
    return 'http://localhost:3000/api';
  }

  static String _normalize(String value) {
    var result = value.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  static String? validateServerUrl(String value, {bool releaseMode = kReleaseMode}) {
    final normalized = _normalize(value);
    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'أدخل عنوانًا صحيحًا مثل http://192.168.1.20:3000/api';
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'العنوان يجب أن يبدأ بـ http:// أو https://';
    }
    if (releaseMode && uri.scheme != 'https') {
      return 'نسخة Release تقبل خادم HTTPS فقط.';
    }
    if (!uri.path.endsWith('/api')) {
      return 'يجب أن ينتهي عنوان الخادم بـ /api';
    }
    return null;
  }

  Future<void> initialize() async {
    final savedUrl = await _serverUrlStorage.read();
    if (savedUrl != null && validateServerUrl(savedUrl) == null) {
      baseUrl = _normalize(savedUrl);
    }
    _token = await _tokenStorage.read();
  }

  Future<void> setBaseUrl(String value) async {
    final error = validateServerUrl(value);
    if (error != null) throw ApiException(0, error);
    baseUrl = _normalize(value);
    await _serverUrlStorage.write(baseUrl);
  }

  Future<void> setToken(String? token) async {
    _token = token;
    if (token == null) {
      await _tokenStorage.clear();
    } else {
      await _tokenStorage.write(token);
    }
  }

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<bool> testConnection() async {
    final response = await _guard(
      () => _client.get(Uri.parse('$baseUrl/health')).timeout(_timeout),
      authenticatedRequest: false,
    );
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>> register(
      String email, String password, String dateOfBirth, String displayName) async {
    final res = await _post('/auth/register', {
      'email': email,
      'password': password,
      'dateOfBirth': dateOfBirth,
      'displayName': displayName,
    }, authenticatedRequest: false);
    final body = _ok(res, 201);
    await setToken(body['accessToken'] as String);
    return body;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _post('/auth/login', {'email': email, 'password': password},
        authenticatedRequest: false);
    final body = _ok(res, 200);
    await setToken(body['accessToken'] as String);
    return body;
  }

  Future<void> logout() async {
    try {
      if (isAuthenticated) await _post('/auth/logout', const {});
    } catch (_) {
      // Local sign-out must always succeed.
    } finally {
      await setToken(null);
    }
  }

  Future<Map<String, dynamic>> myProfile() async => _ok(await _get('/profiles/me'), 200);
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> fields) async =>
      _ok(await _patch('/profiles/me', fields), 200);
  Future<List<Map<String, dynamic>>> discovery() async => _okList(await _get('/discovery'), 200);
  Future<Map<String, dynamic>> like(String targetUserId, {String kind = 'LIKE'}) async =>
      _ok(await _post('/interactions/like', {'targetUserId': targetUserId, 'kind': kind}), 201);
  Future<List<Map<String, dynamic>>> matches() async =>
      _okList(await _get('/interactions/matches'), 200);
  Future<List<Map<String, dynamic>>> messages(String matchId) async =>
      _okList(await _get('/messaging/$matchId'), 200);
  Future<Map<String, dynamic>> sendMessage(String matchId, String body) async =>
      _ok(await _post('/messaging/send', {'matchId': matchId, 'body': body}), 201);
  Future<void> block(String targetUserId) async =>
      _ok(await _post('/users/block', {'targetUserId': targetUserId}), 201);
  Future<void> report(String targetUserId, String reason, {String details = ''}) async =>
      _ok(await _post('/users/report', {
        'targetUserId': targetUserId,
        'reason': reason,
        'details': details,
      }), 201);

  Future<void> deleteAccount() async {
    _ok(await _delete('/users/me'), 200);
    await setToken(null);
  }

  Future<http.Response> _get(String path) => _guard(
      () => _client.get(Uri.parse('$baseUrl$path'), headers: _headers).timeout(_timeout));

  Future<http.Response> _post(String path, Object body,
          {bool authenticatedRequest = true}) =>
      _guard(
        () => _client
            .post(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body))
            .timeout(_timeout),
        authenticatedRequest: authenticatedRequest,
      );

  Future<http.Response> _patch(String path, Object body) => _guard(() => _client
      .patch(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body))
      .timeout(_timeout));

  Future<http.Response> _delete(String path) => _guard(
      () => _client.delete(Uri.parse('$baseUrl$path'), headers: _headers).timeout(_timeout));

  Future<http.Response> _guard(
    Future<http.Response> Function() call, {
    bool authenticatedRequest = true,
  }) async {
    late http.Response res;
    try {
      res = await call();
    } on SocketException {
      throw ApiException(0, 'تعذّر الاتصال بالخادم. تحقق من الشبكة وعنوان الخادم.');
    } on TimeoutException {
      throw ApiException(0, 'انتهت مهلة الاتصال بالخادم.');
    } on http.ClientException {
      throw ApiException(0, 'تعذّر الاتصال بالخادم. تحقق من الشبكة وعنوان الخادم.');
    }

    if (res.statusCode == 401 && authenticatedRequest && isAuthenticated) {
      await setToken(null);
      if (!_handlingUnauthorized) {
        _handlingUnauthorized = true;
        try {
          await onUnauthorized?.call();
        } finally {
          _handlingUnauthorized = false;
        }
      }
    }
    return res;
  }

  Map<String, dynamic> _ok(http.Response response, int expected) {
    final body = _decode(response);
    if (response.statusCode == expected) return body;
    throw ApiException(response.statusCode, _msg(body));
  }

  List<Map<String, dynamic>> _okList(http.Response response, int expected) {
    if (response.statusCode == expected) {
      final decoded = response.body.isEmpty ? [] : jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(decoded as List);
    }
    throw ApiException(response.statusCode, _msg(_decode(response)));
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) return {};
    try {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  String _msg(Map<String, dynamic> body) {
    final message = body['message'];
    if (message is List) return message.join(', ');
    return message?.toString() ?? 'فشل الطلب';
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  bool get isNetwork => statusCode == 0;
  @override
  String toString() => message;
}
