import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../widgets/safety_actions.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  List<Map<String, dynamic>> _candidates = [];
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
      _candidates = await widget.api.discovery();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _like(String userId, String name, {String kind = 'LIKE'}) async {
    try {
      final res = await widget.api.like(userId, kind: kind);
      if (!mounted) return;
      final matched = res['matched'] == true;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(matched ? '🎉 مطابقة جديدة مع $name!' : 'أعجبك $name'),
      ));
      setState(() => _candidates.removeWhere((c) => c['userId'] == userId));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اكتشاف'), actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _candidates.isEmpty
                  ? const Center(child: Text('لا يوجد أشخاص جدد الآن'))
                  : ListView.builder(
                      key: const Key('discover_list'),
                      padding: const EdgeInsets.all(12),
                      itemCount: _candidates.length,
                      itemBuilder: (_, i) {
                        final c = _candidates[i];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(c['displayName'] ?? '',
                                          style: Theme.of(context).textTheme.titleLarge),
                                    ),
                                    IconButton(
                                      key: Key('discover_more_${c['userId']}'),
                                      icon: const Icon(Icons.more_vert),
                                      tooltip: 'خيارات السلامة',
                                      onPressed: () async {
                                        final blocked = await SafetyActions.showMenu(
                                          context, widget.api, c['userId'], c['displayName'] ?? '');
                                        if (blocked && mounted) {
                                          setState(() => _candidates
                                              .removeWhere((x) => x['userId'] == c['userId']));
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                if ((c['country'] ?? '').toString().isNotEmpty)
                                  Text(c['country'], style: const TextStyle(color: Colors.grey)),
                                const SizedBox(height: 6),
                                Text(c['bio'] ?? ''),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _like(c['userId'], c['displayName'], kind: 'SUPER_LIKE'),
                                      icon: const Icon(Icons.star, color: Colors.amber),
                                      label: const Text('Super'),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton.icon(
                                      onPressed: () => _like(c['userId'], c['displayName']),
                                      icon: const Icon(Icons.favorite),
                                      label: const Text('إعجاب'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
