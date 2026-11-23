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
import '../../models/store.dart';
import '../gifts/gift_picker.dart';

/// Opening a chat with someone you have no thread with. What this screen says
/// depends on `chat.gate_mode`, exactly as the website does:
///
///  * hard — opening costs `pricing.unlock_coins` up front; after that,
///    messaging is free. A gift opens the chat too.
///  * soft — opening is FREE. The opener gets `chat.free_messages` messages,
///    and only after those is the same price asked to keep going (the thread
///    screen handles that). So nothing here may mention a price.
///
/// A match (or an existing thread) needs no screen at all: it goes straight
/// to the thread, free.
class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key, required this.userId, this.name});
  final String userId;
  final String? name;
  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  bool _busy = false;
  bool _checked = false;

  String get _who => (widget.name == null || widget.name!.isEmpty) ? 'This member' : widget.name!;

  @override
  void initState() {
    super.initState();
    // The mode and the price are dashboard settings that can change while the
    // app is open. Quoting a stale one is worse than a spinner, so re-read them
    // every time a chat is about to open (the server is the authority anyway).
    Future.microtask(() => ref.invalidate(storeProvider));
    _tryFree();
  }

  /// A match, or a thread that already exists, costs nothing and needs no
  /// explanation. `unlock_conversation` returns the existing thread rather
  /// than charging twice, so a wrong guess here is harmless; the check only
  /// decides whether to show a price screen at all.
  Future<void> _tryFree() async {
    final api = ref.read(apiClientProvider);
    try {
      final matches = asMapList((await api.getJson('/matches'))['items']);
      final match = matches.where((r) => asString(asMap(r['profile'])['user_id']) == widget.userId).firstOrNull;
      if (match != null) {
        final conv = asString(match['conversation_id']);
        if (conv != null) return _go(conv);
        return _open();
      }
      final convs = asMapList((await api.getJson('/conversations'))['items']);
      final existing = convs.where((c) => asString(asMap(c['other'])['user_id']) == widget.userId).firstOrNull;
      if (existing != null) return _go(asString(existing['id'])!);
    } catch (_) {
      // Fall through to the screen; the unlock call is the source of truth.
    }
    if (mounted) setState(() => _checked = true);
  }

  void _go(String id) {
    if (mounted) context.pushReplacement('/messages/$id');
  }

  Future<void> _open() async {
    setState(() => _busy = true);
    try {
      final r = await ref.read(apiClientProvider).postJson('/conversations/unlock', data: {'to': widget.userId});
      final charged = asInt(r['charged']) ?? 0;
      final balance = asInt(r['balance']);
      if (balance != null) ref.read(meProvider.notifier).setBalance(balance);
      if (charged > 0 && mounted) showToast(context, '$charged coins spent to open this chat');
      _go(asString(r['conversation_id'])!);
    } catch (e) {
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _gift() async {
    final conv = await GiftSheet.show(context, ref, toUserId: widget.userId, toName: _who);
    if (conv != null) _go(conv);
  }

  @override
  Widget build(BuildContext context) {
    final storeAsync = ref.watch(storeProvider);
    // Wait for the real settings. Defaulting to hard here is what made this
    // screen quote a price on a platform that opens chats free.
    final Widget body = !_checked
        ? const LoadingView()
        : storeAsync.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(storeProvider)),
            data: _content,
          );
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white),
      body: body,
    );
  }

  Widget _content(Store store) {
    final me = ref.watch(meProvider).valueOrNull;
    final soft = store.softGate;
    final free = me?.perks.freeUnlocks ?? false;
    final cost = store.unlockCoins;
    final balance = me?.balance ?? 0;
    // Under soft gating the door is free, so there is nothing to be short OF.
    final short = !soft && !free && balance < cost;
    final n = store.chatFreeMessages;

    final title = 'Open a conversation';
    final body = soft && !free
        ? 'Say hello to $_who. ${n == 1 ? 'Your first message is free' : 'Your first $n messages are free'}; after that you can unlock the chat to keep going.'
        : free
            ? 'Your plan includes free chats, so there is nothing to pay.'
            : short
                ? '$_who has not liked you yet. Opening the chat costs $cost coins and you have $balance. Get coins, or send a gift, which opens it too.'
                : '$_who has not liked you yet. Opening the chat costs $cost coins — or send a gift, which opens it too.';
    final cta = soft && !free ? 'Start chatting — free' : free ? 'Open chat' : 'Open chat · $cost coins';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const Spacer(),
          const Icon(Icons.lock_open_rounded, color: AppColors.gold, size: 54),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(body, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, height: 1.45)),
          if (!soft && !free) ...[const SizedBox(height: 14), CoinAmount(balance)],
          const Spacer(),
          if (short)
            PrimaryButton(label: 'Get coins', icon: Icons.toll_rounded, onPressed: () => context.push('/wallet'))
          else
            PrimaryButton(label: cta, loading: _busy, onPressed: _open),
          const SizedBox(height: 10),
          SecondaryButton(label: 'Send a gift instead', icon: Icons.card_giftcard_rounded, onPressed: _gift),
          const SizedBox(height: 4),
          TextButton(onPressed: () => context.pop(), child: const Text('Not now', style: TextStyle(color: Colors.white54))),
        ]),
      ),
    );
  }
}
