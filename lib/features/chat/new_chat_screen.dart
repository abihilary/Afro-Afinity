import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/colors.dart';
import '../../core/api/api_client.dart';
import '../../core/state/providers.dart';
import '../../core/ui/api_errors.dart';
import '../../core/util/json.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/common.dart';

/// Opening a chat with someone you have no thread with. On a match the
/// unlock is free; otherwise it costs `pricing.unlock_coins` (or nothing
/// with the `free_unlocks` perk) — so the price is shown and confirmed
/// before anything is spent. Then this screen replaces itself with the thread.
class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key, required this.userId});
  final String userId;
  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  bool _busy = false;
  Object? _error;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _tryFree();
  }

  /// A match (or an existing thread) costs nothing, and `unlock_conversation`
  /// returns the existing thread rather than charging twice. Ask the profile
  /// relation first so we only show a price when there is one.
  Future<void> _tryFree() async {
    try {
      final rows = asMapList((await ref.read(apiClientProvider).getJson('/matches'))['items']);
      final match = rows.where((r) => asString(asMap(r['profile'])['user_id']) == widget.userId).firstOrNull;
      if (match != null) {
        final conv = asString(match['conversation_id']);
        if (conv != null) return _go(conv);
        return _unlock();
      }
      final convs = asMapList((await ref.read(apiClientProvider).getJson('/conversations'))['items']);
      final existing = convs.where((c) => asString(asMap(c['other'])['user_id']) == widget.userId).firstOrNull;
      if (existing != null) return _go(asString(existing['id'])!);
    } catch (_) {
      // Fall through to the priced confirmation; the unlock call is the truth.
    }
    if (mounted) setState(() => _checked = true);
  }

  void _go(String id) {
    if (mounted) context.pushReplacement('/messages/$id');
  }

  Future<void> _unlock() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await ref.read(apiClientProvider).postJson('/conversations/unlock', data: {'to': widget.userId});
      final charged = asInt(r['charged']) ?? 0;
      final balance = asInt(r['balance']);
      if (balance != null) ref.read(meProvider.notifier).setBalance(balance);
      if (charged > 0 && mounted) showToast(context, '$charged coins spent to open this chat');
      _go(asString(r['conversation_id'])!);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
      handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider).valueOrNull;
    final store = ref.watch(storeProvider).valueOrNull;
    final free = me?.perks.freeUnlocks ?? false;
    final cost = store?.unlockCoins ?? 30;
    final short = !free && (me?.balance ?? 0) < cost;
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white),
      body: !_checked && _error == null
          ? const LoadingView()
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  const Spacer(),
                  const Icon(Icons.lock_open_rounded, color: AppColors.gold, size: 54),
                  const SizedBox(height: 16),
                  const Text('Start a conversation', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Text(
                    free
                        ? 'Your plan includes free chat unlocks.'
                        : 'You have not matched yet. Opening a chat costs $cost coins — after that, messaging is free.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  CoinAmount(me?.balance ?? 0),
                  const Spacer(),
                  if (short)
                    PrimaryButton(label: 'Top up coins', icon: Icons.toll_rounded, onPressed: () => context.push('/wallet'))
                  else
                    PrimaryButton(label: free ? 'Open chat' : 'Open chat for $cost coins', loading: _busy, onPressed: _unlock),
                  const SizedBox(height: 10),
                  SecondaryButton(label: 'Not now', onPressed: () => context.pop()),
                ]),
              ),
            ),
    );
  }
}
