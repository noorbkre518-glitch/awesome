import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';

import '../api/api_client.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final TextEditingController _server;
  String? _error;
  String? _serverStatus;
  bool _busy = false;
  bool _testingServer = false;

  @override
  void initState() {
    super.initState();
    _server = TextEditingController(text: widget.api.baseUrl);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _server.dispose();
    super.dispose();
  }

  Future<bool> _saveServer() async {
    final value = _server.text.trim();
    final validation = ApiClient.validateServerUrl(value);
    if (validation != null) {
      if (mounted) setState(() => _error = validation);
      return false;
    }
    try {
      await widget.api.setBaseUrl(value);
      return true;
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
      return false;
    }
  }

  Future<void> _testServer() async {
    setState(() {
      _testingServer = true;
      _serverStatus = null;
      _error = null;
    });
    try {
      if (!await _saveServer()) return;
      final ok = await widget.api.testConnection();
      if (!mounted) return;
      setState(() => _serverStatus = ok
          ? 'تم الاتصال بالخادم بنجاح ✓'
          : 'الخادم لم يُرجع حالة سليمة.');
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _testingServer = false);
    }
  }

  Future<void> _login() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!await _saveServer()) return;
      await widget.api.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen(api: widget.api)),
        (_) => false,
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aurora — تسجيل الدخول')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('اتصال الخادم',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('server_url'),
                        controller: _server,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: 'عنوان الخادم',
                          helperText: kReleaseMode
                              ? 'Release: استخدم HTTPS وينتهي بـ /api'
                              : 'للهاتف: http://IP-الكمبيوتر:3000/api',
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        key: const Key('test_server'),
                        onPressed: _testingServer || _busy ? null : _testServer,
                        icon: _testingServer
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.wifi_tethering),
                        label: const Text('اختبار الاتصال'),
                      ),
                      if (_serverStatus != null)
                        Text(_serverStatus!,
                            style: const TextStyle(color: Colors.greenAccent)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('login_email'),
                controller: _email,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('login_password'),
                controller: _password,
                decoration: const InputDecoration(labelText: 'كلمة المرور'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.redAccent)),
                ),
              FilledButton(
                key: const Key('login_submit'),
                onPressed: _busy ? null : _login,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('دخول'),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () async {
                        if (!await _saveServer() || !context.mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => RegisterScreen(api: widget.api)),
                        );
                      },
                child: const Text('ليس لديك حساب؟ إنشاء حساب'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
