import 'package:flutter/material.dart';
import '../api/api_client.dart';

/// Shared block / report actions used from Discover and Chat so the trust &
/// safety flow looks and behaves the same everywhere.
class SafetyActions {
  static const List<String> reasons = [
    'محتوى غير لائق',
    'مضايقة أو تنمّر',
    'رسائل مزعجة (سبام)',
    'حساب مزيّف',
    'سبب آخر',
  ];

  /// Bottom-sheet menu offering Block and Report for [name] ([userId]).
  /// Returns true if the user was blocked (so callers can remove them from a list).
  static Future<bool> showMenu(
    BuildContext context,
    ApiClient api,
    String userId,
    String name,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('safety_report'),
              leading: const Icon(Icons.flag_outlined, color: Colors.orange),
              title: const Text('الإبلاغ عن المستخدم'),
              onTap: () => Navigator.pop(ctx, 'report'),
            ),
            ListTile(
              key: const Key('safety_block'),
              leading: const Icon(Icons.block, color: Colors.redAccent),
              title: const Text('حظر المستخدم'),
              onTap: () => Navigator.pop(ctx, 'block'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('إلغاء'),
              onTap: () => Navigator.pop(ctx, null),
            ),
          ],
        ),
      ),
    );
    if (action == null) return false;
    if (!context.mounted) return false;
    if (action == 'block') return block(context, api, userId, name);
    if (action == 'report') return report(context, api, userId, name);
    return false;
  }

  static Future<bool> block(
    BuildContext context,
    ApiClient api,
    String userId,
    String name,
  ) async {
    // Capture the messenger up-front so we never touch context after an await.
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حظر المستخدم'),
        content: Text('سيتم حظر $name. لن تتمكنا من المراسلة أو الظهور لبعضكما.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            key: const Key('confirm_block'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حظر'),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    try {
      await api.block(userId);
      messenger.showSnackBar(SnackBar(content: Text('تم حظر $name')));
      return true;
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('تعذّر الحظر: $e')));
      return false;
    }
  }

  static Future<bool> report(
    BuildContext context,
    ApiClient api,
    String userId,
    String name,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('الإبلاغ عن $name'),
        children: [
          for (final r in reasons)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, r),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(r)),
            ),
        ],
      ),
    );
    if (reason == null) return false;
    try {
      await api.report(userId, reason);
      messenger.showSnackBar(SnackBar(content: Text('تم استلام بلاغك عن $name. شكرًا لك.')));
      return true;
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('تعذّر إرسال البلاغ: $e')));
      return false;
    }
  }
}
