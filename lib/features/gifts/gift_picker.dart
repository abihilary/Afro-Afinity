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
import '../../models/store.dart';

/// The gift catalogue from `/store`, sent with `POST /conversations/gift`.
/// A gift opens the conversation if there is none, so the result carries the
/// conversation id.
class GiftSheet extends ConsumerStatefulWidget {
  const GiftSheet({super.key, required this.toUserId, required this.toName});
  final String toUserId;
  final String toName;

  /// Returns the conversation id the gift landed in, or null if none was sent.
  static Future<String?> show(BuildContext context, WidgetRef ref, {required String toUserId, required String toName}) {
    if (!ensureVerified(context, ref)) return Future.value(null);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => GiftSheet(toUserId: toUserId, toName: toName),
    );
  }

  @override
  ConsumerState<GiftSheet> createState() => _GiftSheetState();
}

class _GiftSheetState extends ConsumerState<GiftSheet> {
  GiftItem? _picked;
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final g = _picked;
    if (g == null) return;
    setState(() => _busy = true);
    try {
      final r = asMap(await ref.read(apiClientProvider).post('/conversations/gift', data: {
        'to': widget.toUserId,
        'code': g.code,
        if (_note.text.trim().isNotEmpty) 'note': _note.text.trim(),
      }));
      final balance = asInt(r['balance']);
      if (balance != null) ref.read(meProvider.notifier).setBalance(balance);
      if (!mounted) return;
      showToast(context, '${g.emoji} ${g.label(ref.read(localeProvider))} sent to ${widget.toName}');
      Navigator.pop(context, asString(r['conversation_id']));
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider);
    final balance = ref.watch(meProvider).valueOrNull?.balance ?? 0;
    final locale = ref.watch(localeProvider);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SheetHandle(),
          Row(children: [
            Expanded(
              child: Text('Send ${widget.toName} a gift',
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
            ),
            CoinAmount(balance),
          ]),
          const SizedBox(height: 4),
          const Text('Gifts open a conversation, and the receiver keeps part of the value.',
              style: TextStyle(color: Colors.white54, fontSize: 12.5)),
          const SizedBox(height: 16),
          store.when(
            loading: () => const SizedBox(height: 180, child: LoadingView()),
            error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(storeProvider)),
            data: (s) => GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: .82,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final g in s.gifts)
                  GestureDetector(
                    onTap: () => setState(() => _picked = g),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: _picked?.code == g.code ? AppColors.gold.withValues(alpha: .16) : AppColors.darkSurface2,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _picked?.code == g.code ? AppColors.gold : Colors.white10),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(g.emoji, style: const TextStyle(fontSize: 30)),
                        const SizedBox(height: 4),
                        Text(g.label(locale), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11.5)),
                        const SizedBox(height: 2),
                        CoinAmount(g.priceCoins, size: 11, color: g.priceCoins > balance ? Colors.white38 : AppColors.gold),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _note,
            maxLength: 280,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'Add a note (optional)', hintStyle: TextStyle(color: Colors.white30)),
          ),
          InlineError(_error),
          const SizedBox(height: 6),
          if (_picked != null && _picked!.priceCoins > balance)
            PrimaryButton(
              label: 'Top up to send',
              icon: Icons.toll_rounded,
              onPressed: () {
                Navigator.pop(context);
                context.push('/wallet');
              },
            )
          else
            PrimaryButton(
              label: _picked == null ? 'Choose a gift' : 'Send for ${_picked!.priceCoins} coins',
              loading: _busy,
              onPressed: _picked == null ? null : _send,
            ),
        ]),
      ),
    );
  }
}
