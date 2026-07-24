import 'package:flutter/material.dart';
import '../api/api_client.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  DateTime? _dob;
  bool _confirmAdult = false;
  String? _error;
  bool _busy = false;

  bool get _isAdult {
    if (_dob == null) return false;
    final now = DateTime.now();
    var age = now.year - _dob!.year;
    if (now.month < _dob!.month || (now.month == _dob!.month && now.day < _dob!.day)) age--;
    return age >= 18;
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _register() async {
    setState(() { _busy = true; _error = null; });
    // Client-side age gate (server also enforces — Master Plan §6/§32).
    if (!_isAdult) {
      setState(() { _error = 'يجب أن يكون عمرك 18 عامًا أو أكثر.'; _busy = false; });
      return;
    }
    if (!_confirmAdult) {
      setState(() { _error = 'يرجى تأكيد أنك بالغ 18+.'; _busy = false; });
      return;
    }
    try {
      final iso = _dob!.toIso8601String().split('T').first;
      await widget.api.register(_email.text.trim(), _password.text, iso, _displayName.text.trim());
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(api: widget.api)),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                key: const Key('reg_displayName'),
                controller: _displayName,
                decoration: const InputDecoration(labelText: 'الاسم الظاهر'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('reg_email'),
                controller: _email,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('reg_password'),
                controller: _password,
                decoration: const InputDecoration(labelText: 'كلمة المرور (8+ أحرف)'),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('reg_dob'),
                onPressed: _pickDob,
                icon: const Icon(Icons.cake_outlined),
                label: Text(_dob == null
                    ? 'اختر تاريخ الميلاد'
                    : 'تاريخ الميلاد: ${_dob!.toIso8601String().split('T').first}'),
              ),
              CheckboxListTile(
                key: const Key('reg_confirmAdult'),
                value: _confirmAdult,
                onChanged: (v) => setState(() => _confirmAdult = v ?? false),
                title: const Text('أؤكد أن عمري 18 عامًا أو أكثر'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                ),
              FilledButton(
                key: const Key('reg_submit'),
                onPressed: _busy ? null : _register,
                child: _busy
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('إنشاء الحساب'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
