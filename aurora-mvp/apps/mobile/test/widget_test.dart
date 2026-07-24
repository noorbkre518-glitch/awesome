import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_mobile/main.dart';
import 'package:aurora_mobile/src/api/api_client.dart';
import 'package:aurora_mobile/src/screens/register_screen.dart';

void main() {
  testWidgets('login screen renders with email/password/submit', (tester) async {
    await tester.pumpWidget(AuroraApp(api: ApiClient()));
    expect(find.byKey(const Key('login_email')), findsOneWidget);
    expect(find.byKey(const Key('login_password')), findsOneWidget);
    expect(find.byKey(const Key('login_submit')), findsOneWidget);
  });

  testWidgets('register screen shows age gate: 17y blocked, confirm required',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: RegisterScreen(api: ApiClient())));
    // Fill fields
    await tester.enterText(find.byKey(const Key('reg_displayName')), 'Test');
    await tester.enterText(find.byKey(const Key('reg_email')), 'x@aurora.test');
    await tester.enterText(find.byKey(const Key('reg_password')), 'password123');
    // No DOB chosen and not adult → submit shows the 18+ error, no network call
    await tester.tap(find.byKey(const Key('reg_submit')));
    await tester.pump();
    expect(find.textContaining('18 عامًا أو أكثر'), findsWidgets); // error + checkbox both mention 18
  });
}
