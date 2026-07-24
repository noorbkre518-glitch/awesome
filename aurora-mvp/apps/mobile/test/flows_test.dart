import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aurora_mobile/src/api/api_client.dart';
import 'package:aurora_mobile/src/screens/login_screen.dart';
import 'package:aurora_mobile/src/screens/home_screen.dart';

ApiClient clientWith(Future<http.Response> Function(http.Request req) handler) =>
    ApiClient(baseUrl: 'http://test/api', httpClient: MockClient(handler));

void main() {
  testWidgets('login flow lands on the Discover home screen', (tester) async {
    final api = clientWith((req) async {
      switch (req.url.path) {
        case '/api/auth/login':
          return http.Response(jsonEncode({'accessToken': 't'}), 200);
        case '/api/discovery':
          return http.Response(jsonEncode([]), 200);
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(MaterialApp(home: LoginScreen(api: api)));
    await tester.enterText(find.byKey(const Key('login_email')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('login_password')), 'password123');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    // Home shows the bottom nav + Discover appbar; empty discovery shows its state.
    expect(find.text('اكتشاف'), findsWidgets);
    expect(find.text('لا يوجد أشخاص جدد الآن'), findsOneWidget);
  });

  testWidgets('liking a candidate that matches shows a match snackbar', (tester) async {
    final api = clientWith((req) async {
      if (req.url.path == '/api/discovery') {
        return http.Response(
            jsonEncode([
              {'userId': 'u2', 'displayName': 'Bob', 'bio': 'hi', 'country': 'NL'}
            ]),
            200);
      }
      if (req.url.path == '/api/interactions/like') {
        return http.Response(jsonEncode({'liked': true, 'matched': true, 'matchId': 'm1'}), 201);
      }
      return http.Response('{}', 404);
    });
    api.setToken('t');

    await tester.pumpWidget(MaterialApp(home: HomeScreen(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Bob'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'إعجاب'));
    await tester.pump(); // let the like future resolve
    await tester.pump(); // build the snackbar
    expect(find.textContaining('مطابقة جديدة'), findsOneWidget);
  });

  testWidgets('blocking a candidate from Discover removes them', (tester) async {
    final api = clientWith((req) async {
      if (req.url.path == '/api/discovery') {
        return http.Response(
            jsonEncode([
              {'userId': 'u2', 'displayName': 'Bob', 'bio': 'hi', 'country': 'NL'}
            ]),
            200);
      }
      if (req.url.path == '/api/users/block') {
        return http.Response('{}', 201);
      }
      return http.Response('{}', 404);
    });
    api.setToken('t');

    await tester.pumpWidget(MaterialApp(home: HomeScreen(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Bob'), findsOneWidget);

    await tester.tap(find.byKey(const Key('discover_more_u2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('safety_block')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_block')));
    await tester.pumpAndSettle();

    expect(find.text('Bob'), findsNothing);
    expect(find.text('لا يوجد أشخاص جدد الآن'), findsOneWidget);
  });

  testWidgets('logout returns the user to the login screen', (tester) async {
    final api = clientWith((req) async {
      switch (req.url.path) {
        case '/api/discovery':
          return http.Response(jsonEncode([]), 200);
        case '/api/profiles/me':
          return http.Response(
              jsonEncode({'displayName': 'Nour', 'bio': '', 'country': ''}), 200);
        case '/api/auth/logout':
          return http.Response('{}', 200);
      }
      return http.Response('{}', 404);
    });
    api.setToken('t');

    await tester.pumpWidget(MaterialApp(home: HomeScreen(api: api)));
    await tester.pumpAndSettle();

    // Switch to the profile tab, then log out.
    await tester.tap(find.text('ملفي'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('logout')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_email')), findsOneWidget);
    expect(api.isAuthenticated, false);
  });
}
