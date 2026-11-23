import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/colors.dart';
import '../../core/api/api_client.dart';
import '../../core/state/providers.dart';
import '../../core/ui/api_errors.dart';
import '../../core/ui/verified_gate.dart';
import '../../core/util/json.dart';
import '../../core/util/time.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/common.dart';
import '../../models/member.dart';
import '../../models/store.dart';
import '../../models/wallet.dart';
import '../profile/forms/form_bits.dart';
import 'purchase_sheet.dart';

final _walletProvider = FutureProvider.autoDispose<Json>((ref) => ref.read(apiClientProvider).getJson('/me/wallet'));
final _ledgerProvider = FutureProvider.autoDispose<List<LedgerEntry>>((ref) async =>
    asMapList((await ref.read(apiClientProvider).getJson('/me/ledger'))['items']).map(LedgerEntry.new).toList());
final _ordersProvider = FutureProvider.autoDispose<List<Order>>((ref) async =>
    asMapList((await ref.read(apiClientProvider).getJson('/orders'))['items']).map(Order.new).toList());
final _transfersProvider = FutureProvider.autoDispose<List<Transfer>>((ref) async =>
    asMapList((await ref.read(apiClientProvider).getJson('/transfers'))['items']).map(Transfer.new).toList());
final _payoutsProvider = FutureProvider.autoDispose<List<Payout>>((ref) async {
  final me = await ref.watch(meProvider.future);
  if (me == null || !me.canInteract) return const [];
  return asMapList((await ref.read(apiClientProvider).getJson('/payouts'))['items']).map(Payout.new).toList();
});

/// Coins: buy (packs or a custom amount), history, send to a member, and cash
/// out earned coins to mobile money. Prices come from `/store` only.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key, this.initialTab});
  final String? initialTab;

  void _refreshAll(WidgetRef ref) {
    ref.invalidate(_walletProvider);
    ref.invalidate(_ledgerProvider);
    ref.invalidate(_ordersProvider);
    ref.invalidate(_transfersProvider);
    ref.invalidate(_payoutsProvider);
    ref.read(meProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const tabs = ['buy', 'history', 'send', 'cashout'];
    final i = tabs.indexOf(initialTab ?? 'buy');
    return DefaultTabController(
      length: 4,
      initialIndex: i < 0 ? 0 : i,
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          backgroundColor: AppColors.black,
          foregroundColor: Colors.white,
          title: const Text('Wallet'),
          bottom: const TabBar(
            indicatorColor: AppColors.gold,
            labelColor: AppColors.gold,
            unselectedLabelColor: Colors.white60,
            dividerColor: Colors.transparent,
            tabs: [Tab(text: 'Buy'), Tab(text: 'History'), Tab(text: 'Send'), Tab(text: 'Cash out')],
          ),
        ),
        body: Column(children: [
          _BalanceCard(onRefresh: () => _refreshAll(ref)),
          Expanded(
            child: TabBarView(children: [
              _BuyTab(onPaid: () => _refreshAll(ref)),
              const _HistoryTab(),
              _SendTab(onSent: () => _refreshAll(ref)),
              _CashOutTab(onRequested: () => _refreshAll(ref)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard({required this.onRefresh});
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = ref.watch(_walletProvider).valueOrNull;
    final me = ref.watch(meProvider).valueOrNull;
    final balance = asInt(w?['balance']) ?? me?.balance ?? 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [Color(0xFF3B2A12), Color(0xFF1A1206)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: AppColors.gold.withValues(alpha: .35)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Balance', style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 4),
            CoinAmount(balance, size: 30),
            const SizedBox(height: 6),
            Text('Earned ${asInt(w?['earned']) ?? me?.earned ?? 0} · ${asInt(w?['payable']) ?? 0} can be cashed out',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ),
        IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh_rounded, color: Colors.white54)),
      ]),
    );
  }
}

class _BuyTab extends ConsumerStatefulWidget {
  const _BuyTab({required this.onPaid});
  final VoidCallback onPaid;
  @override
  ConsumerState<_BuyTab> createState() => _BuyTabState();
}

class _BuyTabState extends ConsumerState<_BuyTab> {
  final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  Future<void> _buy(PurchaseItem item) async {
    if (await showPurchaseSheet(context, item)) widget.onPaid();
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(storeProvider).when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(storeProvider)),
          data: (s) {
            final custom = s.custom;
            final perCoin = asDouble(custom?['per_coin']);
            final n = int.tryParse(_custom.text) ?? 0;
            final minC = asInt(custom?['min_coins']) ?? 20;
            final maxC = asInt(custom?['max_coins']) ?? 100000;
            return ListView(padding: const EdgeInsets.fromLTRB(16, 10, 16, 30), children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.05,
                children: [for (final p in s.packs) _PackCard(pack: p, store: s, onTap: () => _buy(PurchaseItem(kind: 'coins', itemCode: p.code, label: '${p.total} coins', amount: p.price)))],
              ),
              if (perCoin != null) ...[
                const FieldLabel('Custom amount'),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _custom,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      style: fieldText,
                      decoration: fieldDecoration('$minC – $maxC coins'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 140,
                    child: PrimaryButton(
                      height: 50,
                      label: n >= minC && n <= maxC ? s.money(n * perCoin) : 'Buy',
                      onPressed: n >= minC && n <= maxC
                          ? () => _buy(PurchaseItem(kind: 'coins', itemCode: 'custom', coins: n, label: '$n coins', amount: n * perCoin))
                          : null,
                    ),
                  ),
                ]),
              ],
              const SizedBox(height: 18),
              const Text('What coins are for', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              _Use('Open a chat before you match', '${s.unlockCoins} coins'),
              _Use('Super like', '${s.superlikeCoins} coins'),
              _Use('Boost for ${s.boostHours} h', '${s.boostCoins} coins'),
              _Use('Gifts', 'from ${s.gifts.isEmpty ? 0 : s.gifts.map((g) => g.priceCoins).reduce((a, b) => a < b ? a : b)} coins'),
            ]);
          },
        );
  }
}

class _Use extends StatelessWidget {
  const _Use(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70))),
          Text(value, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
        ]),
      );
}

class _PackCard extends StatelessWidget {
  const _PackCard({required this.pack, required this.store, required this.onTap});
  final CoinPack pack;
  final Store store;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final hot = pack.badge != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: hot ? AppColors.gold : Colors.white10, width: hot ? 1.5 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (hot)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(8)),
              child: Text(pack.badge == 'best' ? 'Best value' : 'Popular', style: const TextStyle(color: Colors.black, fontSize: 10.5, fontWeight: FontWeight.w800)),
            ),
          const Spacer(),
          CoinAmount(pack.coins, size: 22),
          if (pack.bonusCoins > 0) Text('+${pack.bonusCoins} bonus', style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(store.money(pack.price), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(_ledgerProvider);
    final orders = ref.watch(_ordersProvider).valueOrNull ?? const [];
    final pending = orders.where((o) => o.status == 'pending').toList();
    final store = ref.watch(storeProvider).valueOrNull;
    return ledger.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(_ledgerProvider)),
      data: (rows) => RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () async {
          ref.invalidate(_ordersProvider);
          final _ = await ref.refresh(_ledgerProvider.future);
        },
        child: rows.isEmpty && pending.isEmpty
            ? ListView(children: const [SizedBox(height: 40), EmptyState(icon: Icons.receipt_long_outlined, title: 'No activity yet')])
            : ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
                for (final o in pending)
                  ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.hourglass_top_rounded, color: Colors.orange, size: 20)),
                    title: Text('Payment pending · ${o.itemCode}', style: const TextStyle(color: Colors.white)),
                    subtitle: Text(shortAgo(o.createdAt), style: const TextStyle(color: Colors.white54)),
                    trailing: Text(store?.money(o.amount) ?? '${o.amount}', style: const TextStyle(color: Colors.white54)),
                  ),
                for (final r in rows)
                  ListTile(
                    leading: r.counterpart != null
                        ? Avatar(url: r.counterpart!.avatarUrl, size: 40)
                        : CircleAvatar(
                            backgroundColor: Colors.white10,
                            child: Icon(r.delta >= 0 ? Icons.south_west_rounded : Icons.north_east_rounded, color: r.delta >= 0 ? AppColors.success : Colors.white60, size: 20),
                          ),
                    title: Text(r.counterpart == null ? r.label : '${r.label} · ${r.counterpart!.name}', style: const TextStyle(color: Colors.white)),
                    subtitle: Text(longDate(r.createdAt), style: const TextStyle(color: Colors.white54)),
                    trailing: Text('${r.delta > 0 ? '+' : ''}${r.delta}',
                        style: TextStyle(color: r.delta >= 0 ? AppColors.success : Colors.white, fontWeight: FontWeight.w800)),
                  ),
              ]),
      ),
    );
  }
}

class _SendTab extends ConsumerStatefulWidget {
  const _SendTab({required this.onSent});
  final VoidCallback onSent;
  @override
  ConsumerState<_SendTab> createState() => _SendTabState();
}

class _SendTabState extends ConsumerState<_SendTab> {
  final _q = TextEditingController();
  final _coins = TextEditingController();
  final _note = TextEditingController();
  List<MemberCard> _results = [];
  MemberCard? _to;
  Timer? _debounce;
  bool _busy = false;

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_q, _coins, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _search(String v) {
    _debounce?.cancel();
    if (v.trim().length < 2) return setState(() => _results = []);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final j = await ref.read(apiClientProvider).getJson('/directory', query: {'q': v.trim(), 'limit': 8});
        if (mounted) setState(() => _results = asMapList(j['items']).map(MemberCard.new).toList());
      } catch (_) {}
    });
  }

  Future<void> _send() async {
    if (!ensureVerified(context, ref)) return;
    final n = int.tryParse(_coins.text) ?? 0;
    if (_to == null || n <= 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface2,
        title: Text('Send $n coins to ${_to!.name}?', style: const TextStyle(color: Colors.white)),
        content: const Text('Transfers cannot be reversed.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).post('/transfers', data: {
        'to': _to!.userId,
        'coins': n,
        if (_note.text.trim().isNotEmpty) 'note': _note.text.trim(),
      });
      if (!mounted) return;
      showToast(context, 'Sent $n coins to ${_to!.name}');
      setState(() {
        _to = null;
        _coins.clear();
        _note.clear();
      });
      widget.onSent();
    } catch (e) {
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider).valueOrNull;
    if (store != null && !store.transfersEnabled) {
      return const EmptyState(icon: Icons.swap_horiz_rounded, title: 'Transfers are switched off', body: 'Sending coins to other members is not available right now.');
    }
    final history = ref.watch(_transfersProvider).valueOrNull ?? const [];
    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 30), children: [
      const FieldLabel('To'),
      if (_to != null)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Avatar(url: _to!.avatarUrl, size: 42),
          title: Text(_to!.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text('@${_to!.username ?? ''}', style: const TextStyle(color: Colors.white54)),
          trailing: IconButton(onPressed: () => setState(() => _to = null), icon: const Icon(Icons.close_rounded, color: Colors.white54)),
        )
      else ...[
        TextField(controller: _q, onChanged: _search, style: fieldText, decoration: fieldDecoration('Search a name or username')),
        for (final m in _results)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Avatar(url: m.avatarUrl, size: 40),
            title: Text(m.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text('@${m.username ?? ''}', style: const TextStyle(color: Colors.white54)),
            onTap: () => setState(() {
              _to = m;
              _results = [];
              _q.clear();
            }),
          ),
      ],
      FieldLabel('Coins', trailing: store == null ? null : 'Minimum ${store.transferMin}'),
      TextField(controller: _coins, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}), style: fieldText, decoration: fieldDecoration('How many')),
      const FieldLabel('Note'),
      TextField(controller: _note, maxLength: 200, style: fieldText, decoration: fieldDecoration('Optional')),
      const SizedBox(height: 10),
      PrimaryButton(label: 'Send coins', loading: _busy, onPressed: _to != null && (int.tryParse(_coins.text) ?? 0) > 0 ? _send : null),
      if (history.isNotEmpty) ...[
        const FieldLabel('Recent transfers'),
        for (final t in history)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Avatar(url: t.counterpart?.avatarUrl, size: 38),
            title: Text('${t.outgoing ? 'To' : 'From'} ${t.counterpart?.name ?? 'member'}', style: const TextStyle(color: Colors.white)),
            subtitle: Text([longDate(t.createdAt), if (t.note != null) t.note!].join(' · '), style: const TextStyle(color: Colors.white54)),
            trailing: Text('${t.outgoing ? '−' : '+'}${t.coins}', style: TextStyle(color: t.outgoing ? Colors.white : AppColors.success, fontWeight: FontWeight.w800)),
          ),
      ],
    ]);
  }
}

class _CashOutTab extends ConsumerStatefulWidget {
  const _CashOutTab({required this.onRequested});
  final VoidCallback onRequested;
  @override
  ConsumerState<_CashOutTab> createState() => _CashOutTabState();
}

class _CashOutTabState extends ConsumerState<_CashOutTab> {
  final _coins = TextEditingController();
  final _phone = TextEditingController(text: '237');
  bool _busy = false;

  @override
  void dispose() {
    _coins.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    if (!ensureVerified(context, ref)) return;
    final n = int.tryParse(_coins.text) ?? 0;
    final phone = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^237[0-9]{9}$').hasMatch(phone)) {
      showToast(context, 'Enter your number as 237 followed by 9 digits.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).post('/payouts', data: {'coins': n, 'momo_number': phone});
      if (!mounted) return;
      showToast(context, 'Payout requested. We send it to $phone after review.');
      _coins.clear();
      widget.onRequested();
    } catch (e) {
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider).valueOrNull;
    final w = ref.watch(_walletProvider).valueOrNull;
    final payable = asInt(w?['payable']) ?? 0;
    final minC = store?.payoutMinCoins ?? 1000;
    final n = int.tryParse(_coins.text) ?? 0;
    final payouts = ref.watch(_payoutsProvider).valueOrNull ?? const [];
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 30), children: [
      SectionCard(
        child: Text(
          'Coins you earn from gifts can be cashed out to mobile money. '
          'Rate: ${store?.payoutPerCoin ?? 5} FCFA per coin. Minimum $minC coins. You can cash out $payable now.',
          style: const TextStyle(color: Colors.white70, height: 1.45),
        ),
      ),
      const FieldLabel('Coins'),
      TextField(controller: _coins, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}), style: fieldText, decoration: fieldDecoration('At least $minC')),
      if (n > 0) Padding(padding: const EdgeInsets.only(top: 6), child: Text('≈ ${store?.money(n * (store.payoutPerCoin)) ?? ''}', style: const TextStyle(color: AppColors.gold))),
      const FieldLabel('MTN or Orange Money number'),
      TextField(controller: _phone, keyboardType: TextInputType.phone, style: fieldText, decoration: fieldDecoration('2376XXXXXXXX')),
      const SizedBox(height: 14),
      PrimaryButton(label: 'Request payout', loading: _busy, onPressed: n >= minC && n <= payable ? _request : null),
      if (payouts.isNotEmpty) ...[
        const FieldLabel('Requests'),
        for (final p in payouts)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${p.coins} coins → ${p.momo ?? ''}', style: const TextStyle(color: Colors.white)),
            subtitle: Text(longDate(p.createdAt), style: const TextStyle(color: Colors.white54)),
            trailing: Text(p.status, style: TextStyle(color: p.status == 'paid' ? AppColors.success : p.status == 'rejected' ? AppColors.error : Colors.orange)),
          ),
      ],
    ]);
  }
}
