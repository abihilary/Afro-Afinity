import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/colors.dart';
import '../../core/api/api_client.dart';
import '../../core/state/providers.dart';
import '../../core/ui/api_errors.dart';
import '../../core/util/time.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/common.dart';
import '../../models/store.dart';
import '../wallet/purchase_sheet.dart';

const _perkLabels = {
  'see_likes': 'See who likes and views you',
  'unlimited_likes': 'Unlimited likes',
  'incognito': 'Incognito — browse unseen',
  'free_unlocks': 'Open chats without coins',
  'advanced_search': 'Advanced search filters',
};

/// Plans from `/store` tiers. Paid in cash (`POST /orders {kind:'plan'}`) or
/// in coins (`/subscription/redeem`). The member's current plan is from `/me`.
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});
  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  String _period = 'monthly';
  bool _busy = false;

  Future<void> _buy(Store s, Tier t) async {
    final p = t.period(_period);
    if (p == null) return;
    final locale = ref.read(localeProvider);
    final paid = await showPurchaseSheet(
      context,
      PurchaseItem(kind: 'plan', itemCode: t.code, period: _period, amount: p.price, label: '${t.label(locale)} · ${_period == 'annual' ? 'yearly' : 'monthly'}'),
    );
    if (paid && mounted) showToast(context, 'Welcome to ${t.label(locale)} ✨');
  }

  Future<void> _redeem(Tier t) async {
    final p = t.period(_period);
    if (p?.coinPrice == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface2,
        title: Text('Pay ${p!.coinPrice} coins?', style: const TextStyle(color: Colors.white)),
        content: Text('${t.labelEn} for one ${_period == 'annual' ? 'year' : 'month'}, paid from your wallet.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Pay with coins')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).post('/subscription/redeem', data: {'code': t.code, 'period': _period});
      await ref.read(meProvider.notifier).refresh();
      if (mounted) showToast(context, 'Welcome to ${t.labelEn} ✨');
    } catch (e) {
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface2,
        title: const Text('Cancel your plan?', style: TextStyle(color: Colors.white)),
        content: const Text('It will not renew. You keep your perks until the end of the period you paid for.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep it')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel plan', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(apiClientProvider).post('/subscription/cancel');
      await ref.read(meProvider.notifier).refresh();
    } catch (e) {
      if (mounted) handleApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider).valueOrNull;
    final locale = ref.watch(localeProvider);
    final sub = me?.subscription;
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(backgroundColor: AppColors.black, foregroundColor: Colors.white, title: const Text('Plans')),
      body: ref.watch(storeProvider).when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(storeProvider)),
            data: (s) => AbsorbPointer(
              absorbing: _busy,
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 30), children: [
                if (sub != null && sub.active)
                  SectionCard(
                    child: Row(children: [
                      const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('You are on ${s.tiers.where((t) => t.code == sub.planCode).firstOrNull?.label(locale) ?? sub.planCode}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                          Text(
                            sub.status == 'cancelled' ? 'Ends ${longDate(sub.currentPeriodEnd)}' : 'Renews ${longDate(sub.currentPeriodEnd)}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12.5),
                          ),
                        ]),
                      ),
                      if (sub.status != 'cancelled') TextButton(onPressed: _cancel, child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
                    ]),
                  ),
                const SizedBox(height: 12),
                Center(
                  child: SegmentedButton<String>(
                    style: SegmentedButton.styleFrom(foregroundColor: Colors.white70, selectedForegroundColor: Colors.black, selectedBackgroundColor: AppColors.gold),
                    showSelectedIcon: false,
                    segments: const [ButtonSegment(value: 'monthly', label: Text('Monthly')), ButtonSegment(value: 'annual', label: Text('Yearly'))],
                    selected: {_period},
                    onSelectionChanged: (v) => setState(() => _period = v.first),
                  ),
                ),
                const SizedBox(height: 14),
                for (final t in s.tiers) _TierCard(
                  tier: t,
                  store: s,
                  period: _period,
                  locale: locale,
                  current: sub != null && sub.active && sub.planCode == t.code,
                  balance: me?.balance ?? 0,
                  onBuy: () => _buy(s, t),
                  onCoins: () => _redeem(t),
                ),
              ]),
            ),
          ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({required this.tier, required this.store, required this.period, required this.locale, required this.current, required this.balance, required this.onBuy, required this.onCoins});
  final Tier tier;
  final Store store;
  final String period;
  final String locale;
  final bool current;
  final int balance;
  final VoidCallback onBuy;
  final VoidCallback onCoins;

  @override
  Widget build(BuildContext context) {
    final p = tier.period(period);
    final top = tier.rank >= 2;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: top ? const LinearGradient(colors: [Color(0xFF2E2A3E), Color(0xFF15131C)]) : null,
        color: top ? null : AppColors.darkSurface,
        border: Border.all(color: current ? AppColors.gold : (top ? AppColors.purple.withValues(alpha: .5) : Colors.white12), width: current ? 2 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(tier.label(locale), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const Spacer(),
          if (current) const Pill('Current', selected: true),
        ]),
        const SizedBox(height: 6),
        if (p != null)
          Text('${store.money(p.price)} / ${period == 'annual' ? 'year' : 'month'}', style: const TextStyle(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.w800))
        else
          const Text('Not available for this period', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 12),
        for (final perk in tier.perks.entries.where((e) => e.value))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(_perkLabels[perk.key] ?? perk.key, style: const TextStyle(color: Colors.white))),
            ]),
          ),
        if (p != null && !current) ...[
          const SizedBox(height: 14),
          PrimaryButton(label: 'Get ${tier.label(locale)}', onPressed: store.methods.isEmpty ? null : onBuy, height: 48),
          if (p.coinPrice != null) ...[
            const SizedBox(height: 8),
            SecondaryButton(
              label: balance >= p.coinPrice! ? 'Pay ${p.coinPrice} coins instead' : '${p.coinPrice} coins — you have $balance',
              onPressed: balance >= p.coinPrice! ? onCoins : null,
            ),
          ],
        ],
      ]),
    );
  }
}
