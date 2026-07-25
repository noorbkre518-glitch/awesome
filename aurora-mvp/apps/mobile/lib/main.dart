import 'package:flutter/material.dart';

import 'src/api/api_client.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  await api.initialize();
  runApp(AuroraApp(api: api));
}

class AuroraApp extends StatefulWidget {
  const AuroraApp({super.key, required this.api});
  final ApiClient api;

  @override
  State<AuroraApp> createState() => _AuroraAppState();
}

class _AuroraAppState extends State<AuroraApp> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  bool _redirecting = false;

  @override
  void initState() {
    super.initState();
    widget.api.onUnauthorized = () async {
      if (_redirecting) return;
      _redirecting = true;
      try {
        _navKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginScreen(api: widget.api)),
          (_) => false,
        );
      } finally {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        _redirecting = false;
      }
    };
  }

  @override
  Widget build(BuildContext context) {
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
      home: widget.api.isAuthenticated
          ? HomeScreen(api: widget.api)
          : LoginScreen(api: widget.api),
    );
  }
}
