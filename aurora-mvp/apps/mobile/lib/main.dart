import 'package:flutter/material.dart';
import 'src/api/api_client.dart';
import 'src/screens/login_screen.dart';

void main() {
  runApp(AuroraApp(api: ApiClient()));
}

class AuroraApp extends StatelessWidget {
  AuroraApp({super.key, required this.api});
  final ApiClient api;

  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Any 401 on an authenticated request (expired token, logged out elsewhere,
    // deleted/suspended account) bounces the user back to a fresh login screen.
    api.onUnauthorized = () {
      api.setToken(null);
      _navKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen(api: api)),
        (_) => false,
      );
    };

    return MaterialApp(
      title: 'Aurora',
      navigatorKey: _navKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C4DF6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: LoginScreen(api: api),
    );
  }
}
