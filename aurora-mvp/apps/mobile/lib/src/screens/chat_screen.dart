import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../widgets/safety_actions.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.api,
    required this.matchId,
    required this.otherUserId,
    required this.title,
  });
  final ApiClient api;
  final String matchId;
  final String otherUserId;
  final String title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _messages = await widget.api.messages(widget.matchId);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    try {
      await widget.api.sendMessage(widget.matchId, text);
      await _load();
      setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton<String>(
            key: const Key('chat_safety_menu'),
            icon: const Icon(Icons.more_vert),
            onSelected: (v) async {
              if (widget.otherUserId.isEmpty) return;
              final navigator = Navigator.of(context);
              if (v == 'report') {
                await SafetyActions.report(context, widget.api, widget.otherUserId, widget.title);
              } else if (v == 'block') {
                final blocked = await SafetyActions.block(
                    context, widget.api, widget.otherUserId, widget.title);
                if (blocked) navigator.pop();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'report', child: Text('الإبلاغ عن المستخدم')),
              PopupMenuItem(value: 'block', child: Text('حظر المستخدم')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                    : _messages.isEmpty
                    ? const Center(child: Text('لا رسائل بعد — ابدأ المحادثة 👋'))
                    : ListView.builder(
                        key: const Key('chat_list'),
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final m = _messages[i];
                          final mine = m['mine'] == true;
                          return Align(
                            alignment: mine ? Alignment.centerLeft : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: mine
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(m['body'] ?? ''),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('chat_input'),
                      controller: _input,
                      decoration: const InputDecoration(hintText: 'اكتب رسالة…', border: OutlineInputBorder()),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(key: const Key('chat_send'), onPressed: _send, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
