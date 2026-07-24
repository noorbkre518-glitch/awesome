import 'package:flutter/material.dart';
import '../api/api_client.dart';
import 'chat_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<Map<String, dynamic>> _matches = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _matches = await widget.api.matches();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مطابقاتي'), actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _matches.isEmpty
                  ? const Center(child: Text('لا مطابقات بعد — ابدأ من الاكتشاف'))
                  : ListView.separated(
                      key: const Key('matches_list'),
                      itemCount: _matches.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final m = _matches[i];
                        return ListTile(
                          leading: CircleAvatar(child: Text((m['otherName'] ?? '?').toString().characters.first)),
                          title: Text(m['otherName'] ?? 'مستخدم'),
                          trailing: const Icon(Icons.chat_bubble_outline),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              api: widget.api,
                              matchId: m['matchId'],
                              otherUserId: m['otherUserId'] ?? '',
                              title: m['otherName'] ?? 'محادثة',
                            ),
                          )),
                        );
                      },
                    ),
    );
  }
}
