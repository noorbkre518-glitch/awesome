import 'package:flutter/material.dart';
import '../api/api_client.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.api, this.embedded = false});
  final ApiClient api;
  final bool embedded;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _displayName = TextEditingController();
  final _bio = TextEditingController();
  final _country = TextEditingController();
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await widget.api.myProfile();
      _displayName.text = (p['displayName'] ?? '').toString();
      _bio.text = (p['bio'] ?? '').toString();
      _country.text = (p['country'] ?? '').toString();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() { _busy = true; _error = null; _status = null; });
    try {
      await widget.api.updateProfile({
        'displayName': _displayName.text.trim(),
        'bio': _bio.text.trim(),
        'country': _country.text.trim(),
      });
      setState(() => _status = 'تم حفظ الملف الشخصي');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _busy = true);
    // Real logout: invalidate the session server-side (bumps tokenVersion), then
    // drop the local token and return to login. Local sign-out happens even if
    // the network call fails.
    await widget.api.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen(api: widget.api)),
      (_) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: const Text('سيتم حذف حسابك وبياناتك نهائيًا. هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            key: const Key('confirm_delete'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.api.deleteAccount();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen(api: widget.api)),
        (_) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ملفي الشخصي'),
        actions: [
          IconButton(
            key: const Key('logout'),
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'خروج',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    TextField(
                      key: const Key('profile_displayName'),
                      controller: _displayName,
                      decoration: const InputDecoration(labelText: 'الاسم الظاهر'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('profile_bio'),
                      controller: _bio,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'نبذة'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('profile_country'),
                      controller: _country,
                      decoration: const InputDecoration(labelText: 'الدولة (رمز مثل NL)'),
                    ),
                    const SizedBox(height: 20),
                    if (_status != null)
                      Text(_status!, style: const TextStyle(color: Colors.greenAccent)),
                    if (_error != null)
                      Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                    const SizedBox(height: 12),
                    FilledButton(
                      key: const Key('profile_save'),
                      onPressed: _busy ? null : _save,
                      child: const Text('حفظ'),
                    ),
                    const Divider(height: 40),
                    OutlinedButton.icon(
                      key: const Key('delete_account'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                      onPressed: _busy ? null : _deleteAccount,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('حذف الحساب نهائيًا'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
