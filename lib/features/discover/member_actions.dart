import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/colors.dart';
import '../../core/api/api_client.dart';
import '../../core/state/providers.dart';
import '../../core/ui/api_errors.dart';
import '../../core/ui/verified_gate.dart';
import '../../core/util/json.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/common.dart';

class LikeResult {
  const LikeResult({required this.matched, this.conversationId});
  final bool matched;
  final String? conversationId;
}

/// Member-to-member actions, shared by Discover, profiles and Connections.
/// Each one checks the verification gate before the call, and routes any
/// refusal through [handleApiError]. They return null/false on failure so the
/// caller can undo an optimistic change.
class MemberActions {
  MemberActions(this.context, this.ref);
  final BuildContext context;
  final WidgetRef ref;

  ApiClient get _api => ref.read(apiClientProvider);

  /// `kind`: like | superlike | pass. A superlike spends coins.
  Future<LikeResult?> like(String userId, String kind) async {
    if (!ensureVerified(context, ref)) return null;
    try {
      final r = await _api.postJson('/likes', data: {'to': userId, 'kind': kind});
      final matched = asBool(r['matched']);
      // A super like spends coins and a match moves the stats: keep /me true.
      if (kind == 'superlike' || matched) ref.read(meProvider.notifier).refresh();
      return LikeResult(matched: matched, conversationId: asString(r['conversation_id']));
    } catch (e) {
      if (context.mounted) handleApiError(context, e);
      return null;
    }
  }

  Future<bool> undoLike(String userId) => _simple(() => _api.delete('/likes/$userId'));

  Future<bool> wink(String userId, String name) async {
    final ok = await _simple(() => _api.post('/winks', data: {'user_id': userId}));
    if (ok && context.mounted) showToast(context, 'You winked at $name 😉');
    return ok;
  }

  Future<bool> setFavorite(String userId, bool on) =>
      _simple(() => on ? _api.post('/favorites/$userId') : _api.delete('/favorites/$userId'));

  Future<bool> friendRequest(String userId, String name) async {
    if (!ensureVerified(context, ref)) return false;
    try {
      final r = await _api.postJson('/friends/requests', data: {'user_id': userId});
      if (context.mounted) {
        showToast(context, asString(r['status']) == 'accepted' ? 'You and $name are now friends' : 'Friend request sent to $name');
      }
      return true;
    } catch (e) {
      if (context.mounted) handleApiError(context, e);
      return false;
    }
  }

  Future<bool> block(String userId, String name) async {
    final yes = await _confirm('Block $name?', 'They will not be able to see you or message you, and you will not see them.', 'Block');
    if (!yes) return false;
    final ok = await _simple(() => _api.post('/blocks/$userId'));
    if (ok && context.mounted) {
      showToast(context, '$name is blocked');
      ref.invalidate(meProvider);
    }
    return ok;
  }

  Future<bool> report(String userId, String name) async {
    if (!ensureVerified(context, ref)) return false;
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _ReportSheet(userId: userId, name: name, api: _api),
    );
    return sent ?? false;
  }

  /// Opens the conversation with this member, unlocking it first if needed
  /// (free on a match, otherwise it costs coins — the screen says how many).
  void openChat(String userId, {String? conversationId}) {
    if (!ensureVerified(context, ref)) return;
    if (conversationId != null) {
      context.push('/messages/$conversationId');
    } else {
      context.push('/messages/new/$userId');
    }
  }

  Future<bool> _simple(Future<dynamic> Function() call) async {
    if (!ensureVerified(context, ref)) return false;
    try {
      await call();
      return true;
    } catch (e) {
      if (context.mounted) handleApiError(context, e);
      return false;
    }
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface2,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(body, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(action, style: const TextStyle(color: AppColors.error))),
        ],
      ),
    );
    return r ?? false;
  }
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.userId, required this.name, required this.api});
  final String userId;
  final String name;
  final ApiClient api;
  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  static const _reasons = {
    'fake': 'Fake profile',
    'scam': 'Scam or asking for money',
    'harassment': 'Harassment',
    'inappropriate': 'Inappropriate photos or messages',
    'underage': 'May be under 18',
    'other': 'Something else',
  };
  String? _reason;
  bool _block = true;
  final _detail = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      await widget.api.post('/reports', data: {
        'target': widget.userId,
        'reason': _reason,
        if (_detail.text.trim().isNotEmpty) 'detail': _detail.text.trim(),
        'block': _block,
      });
      if (!mounted) return;
      showToast(context, 'Thank you. Our team will look at this.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SheetHandle(),
            Text('Report ${widget.name}', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Reports are private. The member is not told who reported them.', style: TextStyle(color: Colors.white54, fontSize: 12.5)),
            const SizedBox(height: 10),
            RadioGroup<String>(
              groupValue: _reason,
              onChanged: (v) => setState(() => _reason = v),
              child: Column(children: [
                for (final r in _reasons.entries)
                  RadioListTile<String>(
                    value: r.key,
                    activeColor: AppColors.gold,
                    contentPadding: EdgeInsets.zero,
                    title: Text(r.value, style: const TextStyle(color: Colors.white)),
                  ),
              ]),
            ),
            TextField(
              controller: _detail,
              maxLength: 1000,
              maxLines: 3,
              minLines: 1,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'What happened? (optional)', hintStyle: TextStyle(color: Colors.white30)),
            ),
            SwitchListTile(
              value: _block,
              onChanged: (v) => setState(() => _block = v),
              activeThumbColor: AppColors.gold,
              contentPadding: EdgeInsets.zero,
              title: const Text('Also block them', style: TextStyle(color: Colors.white)),
            ),
            InlineError(_error),
            const SizedBox(height: 8),
            PrimaryButton(label: 'Send report', loading: _busy, onPressed: _reason == null ? null : _send),
          ]),
        ),
      ),
    );
  }
}
