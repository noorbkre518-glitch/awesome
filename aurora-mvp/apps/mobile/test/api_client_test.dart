import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aurora_mobile/src/api/api_client.dart';

/// Builds an ApiClient whose HTTP layer is a canned handler, so we exercise the
/// real client logic (token handling, 401 → onUnauthorized, error mapping)
/// without any network.
ApiClient clientWith(Future<http.Response> Function(http.Request req) handler) {
  return ApiClient(baseUrl: 'http://test/api', httpClient: MockClient(handler));
}

void main() {
  test('login stores the token and authenticates subsequent calls', () async {
    final api = clientWith((req) async {
      if (req.url.path == '/api/auth/login') {
        return http.Response(jsonEncode({'accessToken': 'tok123'}), 200);
      }
      if (req.url.path == '/api/profiles/me') {
        expect(req.headers['authorization'], 'Bearer tok123');
        return http.Response(jsonEncode({'displayName': 'Nour'}), 200);
      }
      return http.Response('{}', 404);
    });
    expect(api.isAuthenticated, false);
    await api.login('a@b.com', 'password123');
    expect(api.isAuthenticated, true);
    final p = await api.myProfile();
    expect(p['displayName'], 'Nour');
  });

  test('a 401 clears the token and fires onUnauthorized', () async {
    var kicked = false;
    final api = clientWith((req) async => http.Response(
          jsonEncode({'message': 'Session expired'}), 401));
    api.setToken('stale');
    api.onUnauthorized = () => kicked = true;

    await expectLater(api.myProfile(), throwsA(isA<ApiException>()));
    expect(kicked, true);
    expect(api.isAuthenticated, false);
  });

  test('network failure surfaces as a friendly ApiException (isNetwork)', () async {
    final api = clientWith((req) async => throw const SocketException('down'));
    try {
      await api.discovery();
      fail('expected ApiException');
    } on ApiException catch (e) {
      expect(e.isNetwork, true);
    }
  });

  test('like → match is decoded correctly', () async {
    final api = clientWith((req) async =>
        http.Response(jsonEncode({'liked': true, 'matched': true, 'matchId': 'm1'}), 201));
    api.setToken('t');
    final res = await api.like('u2');
    expect(res['matched'], true);
    expect(res['matchId'], 'm1');
  });

  test('block and report post to the safety endpoints', () async {
    final calls = <String>[];
    final api = clientWith((req) async {
      calls.add(req.url.path);
      return http.Response('{}', 201);
    });
    api.setToken('t');
    await api.block('u2');
    await api.report('u2', 'spam');
    expect(calls, containsAll(['/api/users/block', '/api/users/report']));
  });

  test('logout clears the local token even if the server errors', () async {
    final api = clientWith((req) async => http.Response('{}', 500));
    api.setToken('t');
    await api.logout();
    expect(api.isAuthenticated, false);
  });

  test('deleteAccount clears the token', () async {
    final api = clientWith((req) async => http.Response('{"deleted":true}', 200));
    api.setToken('t');
    await api.deleteAccount();
    expect(api.isAuthenticated, false);
  });
}
