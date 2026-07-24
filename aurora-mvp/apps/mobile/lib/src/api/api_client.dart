import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, SocketException;
import 'package:http/http.dart' as http;

/// Thin REST client for the Aurora API.
///
/// Base URL resolution (in priority order):
///   1. `--dart-define=API_BASE=...` (any environment: emulator, LAN phone, prod)
///   2. Android → `http://10.0.2.2:3000/api` (emulator reaches host localhost)
///   3. otherwise → `http://localhost:3000/api` (desktop / web)
///
/// See README / FINAL_MVP_REPORT for the exact URLs to use per target.
class ApiClient {
  ApiClient({String? baseUrl, http.Client? httpClient})
      : baseUrl = baseUrl ?? _defaultBase(),
        _client = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  String? _token;

  /// Invoked whenever an authenticated request comes back 401 (token expired,
  /// logged out elsewhere, account deleted/suspended). The app wires this to
  /// bounce the user back to the login screen.
  void Function()? onUnauthorized;

  static const Duration _timeout = Duration(seconds: 15);

  static String _defaultBase() {
    const fromEnv = String.fromEnvironment('API_BASE');
    if (fromEnv.isNotEmpty) return fromEnv;
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    } catch (_) {}
    return 'http://localhost:3000/api';
  }

  void setToken(String? t) => _token = t;
  bool get isAuthenticated => _token != null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ---- Auth ----------------------------------------------------------------

  Future<Map<String, dynamic>> register(
      String email, String password, String dateOfBirth, String displayName) async {
    final res = await _post('/auth/register', {
      'email': email,
      'password': password,
      'dateOfBirth': dateOfBirth,
      'displayName': displayName,
    });
    final body = _ok(res, 201);
    _token = body['accessToken'] as String;
    return body;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _post('/auth/login', {'email': email, 'password': password});
    final body = _ok(res, 200);
    _token = body['accessToken'] as String;
    return body;
  }

  /// Real logout: tells the server to invalidate the session, then clears the
  /// local token. Even if the network call fails we still drop the local token.
  Future<void> logout() async {
    try {
      await _post('/auth/logout', const {});
    } on ApiException {
      // Ignore server/network errors on logout — local sign-out must still happen.
    } finally {
      _token = null;
    }
  }

  // ---- Profile -------------------------------------------------------------

  Future<Map<String, dynamic>> myProfile() async =>
      _ok(await _get('/profiles/me'), 200);

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> fields) async =>
      _ok(await _patch('/profiles/me', fields), 200);

  // ---- Discovery / interactions -------------------------------------------

  Future<List<Map<String, dynamic>>> discovery() async =>
      _okList(await _get('/discovery'), 200);

  Future<Map<String, dynamic>> like(String targetUserId, {String kind = 'LIKE'}) async =>
      _ok(await _post('/interactions/like', {'targetUserId': targetUserId, 'kind': kind}), 201);

  Future<List<Map<String, dynamic>>> matches() async =>
      _okList(await _get('/interactions/matches'), 200);

  // ---- Messaging -----------------------------------------------------------

  Future<List<Map<String, dynamic>>> messages(String matchId) async =>
      _okList(await _get('/messaging/$matchId'), 200);

  Future<Map<String, dynamic>> sendMessage(String matchId, String body) async =>
      _ok(await _post('/messaging/send', {'matchId': matchId, 'body': body}), 201);

  // ---- Safety (block / report) --------------------------------------------

  Future<void> block(String targetUserId) async {
    _ok(await _post('/users/block', {'targetUserId': targetUserId}), 201);
  }

  Future<void> report(String targetUserId, String reason, {String details = ''}) async {
    _ok(await _post('/users/report', {
      'targetUserId': targetUserId,
      'reason': reason,
      'details': details,
    }), 201);
  }

  // ---- Account -------------------------------------------------------------

  Future<void> deleteAccount() async {
    _ok(await _delete('/users/me'), 200);
    _token = null;
  }

  // ---- HTTP plumbing -------------------------------------------------------

  Future<http.Response> _get(String path) =>
      _guard(() => _client.get(Uri.parse('$baseUrl$path'), headers: _headers).timeout(_timeout));

  Future<http.Response> _post(String path, Object body) => _guard(() => _client
      .post(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body))
      .timeout(_timeout));

  Future<http.Response> _patch(String path, Object body) => _guard(() => _client
      .patch(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body))
      .timeout(_timeout));

  Future<http.Response> _delete(String path) =>
      _guard(() => _client.delete(Uri.parse('$baseUrl$path'), headers: _headers).timeout(_timeout));

  /// Runs an HTTP call, turning connectivity failures into a friendly
  /// [ApiException] and firing [onUnauthorized] on a 401.
  Future<http.Response> _guard(Future<http.Response> Function() call) async {
    late http.Response res;
    try {
      res = await call();
    } on SocketException {
      throw ApiException(0, 'تعذّر الاتصال بالخادم. تحقق من الشبكة وعنوان الـAPI.');
    } on TimeoutException {
      throw ApiException(0, 'انتهت مهلة الاتصال بالخادم.');
    } on http.ClientException {
      throw ApiException(0, 'تعذّر الاتصال بالخادم. تحقق من الشبكة وعنوان الـAPI.');
    }
    if (res.statusCode == 401) {
      _token = null;
      onUnauthorized?.call();
    }
    return res;
  }

  Map<String, dynamic> _ok(http.Response r, int expected) {
    final body = _decode(r);
    if (r.statusCode == expected) return body;
    throw ApiException(r.statusCode, _msg(body));
  }

  List<Map<String, dynamic>> _okList(http.Response r, int expected) {
    if (r.statusCode == expected) {
      final decoded = r.body.isEmpty ? [] : jsonDecode(r.body);
      return List<Map<String, dynamic>>.from(decoded as List);
    }
    throw ApiException(r.statusCode, _msg(_decode(r)));
  }

  Map<String, dynamic> _decode(http.Response r) {
    if (r.body.isEmpty) return {};
    final d = jsonDecode(r.body);
    return d is Map<String, dynamic> ? d : {};
  }

  String _msg(Map<String, dynamic> b) {
    final m = b['message'];
    if (m is List) return m.join(', ');
    return m?.toString() ?? 'Request failed';
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  /// True when the failure was a connectivity/timeout problem rather than an
  /// HTTP error response from the server.
  bool get isNetwork => statusCode == 0;

  @override
  String toString() => message;
}
