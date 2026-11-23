import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config/api_config.dart';
import '../../app/theme/colors.dart';
import '../../core/api/api_client.dart';
import '../../core/state/providers.dart';
import '../../core/ui/api_errors.dart';
import '../../core/util/json.dart';
import '../../core/util/links.dart';
import '../../core/widgets/common.dart';
import '../../models/store.dart';

/// What is being bought. The price shown is what `/store` quoted; the order
/// carries only codes, and the server prices it again (`quote_coins`).
class PurchaseItem {
  const PurchaseItem({required this.kind, required this.itemCode, required this.label, required this.amount, this.period, this.coins});
  final String kind; // coins | plan
  final String itemCode;
  final String label;
  final double amount;
  final String? period;
  final int? coins; // custom top-ups only
}

/// Returns true when the order was paid.
Future<bool> showPurchaseSheet(BuildContext context, PurchaseItem item) async {
  final r = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    backgroundColor: AppColors.darkSurface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _PurchaseSheet(item: item),
  );
  return r ?? false;
}

class _PurchaseSheet extends ConsumerStatefulWidget {
  const _PurchaseSheet({required this.item});
  final PurchaseItem item;
  @override
  ConsumerState<_PurchaseSheet> createState() => _PurchaseSheetState();
}

enum _Phase { form, waiting, manual, timeout, done }

class _PurchaseSheetState extends ConsumerState<_PurchaseSheet> {
  static final _momo = RegExp(r'^237[0-9]{9}$');
  PaymentMethod? _method;
  final _phone = TextEditingController(text: '237');
  final _promo = TextEditingController();
  Json? _promoQuote;
  bool _busy = false;
  _Phase _phase = _Phase.form;
  Timer? _poll;
  String? _error;

  @override
  void dispose() {
    _poll?.cancel();
    _phone.dispose();
    _promo.dispose();
    super.dispose();
  }

  Future<void> _checkPromo() async {
    final code = _promo.text.trim();
    if (code.length < 2) return;
    setState(() => _busy = true);
    try {
      final q = await ref.read(apiClientProvider).postJson('/promos/check', data: {
        'code': code,
        'kind': widget.item.kind,
        'item_code': widget.item.itemCode,
        'period': ?widget.item.period,
        'coins': ?widget.item.coins,
      });
      setState(() => _promoQuote = q);
    } catch (e) {
      setState(() {
        _promoQuote = null;
        _error = errorText(e);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay() async {
    final m = _method;
    if (m == null) return;
    final phone = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (m.needs == 'phone' && !_momo.hasMatch(phone)) {
      setState(() => _error = 'Enter your number as 237 followed by 9 digits.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await ref.read(apiClientProvider).postJson('/orders', data: {
        'kind': widget.item.kind,
        'item_code': widget.item.itemCode,
        'period': ?widget.item.period,
        'coins': ?widget.item.coins,
        'method': m.id,
        if (m.needs == 'phone') 'momo_number': phone,
        if (_promoQuote != null) 'promo': _promo.text.trim(),
        if (m.needs == 'redirect') 'return_url': '${ApiConfig.webUrl}/app/wallet',
      });
      final status = asString(r['status']);
      final orderId = asString(asMap(r['order'])['id']);
      if (status == 'paid') return _done();
      if (status == 'failed') {
        setState(() => _error = 'The payment did not go through.');
        return;
      }
      final instructions = asString(r['instructions']);
      if (instructions == 'redirect' && asString(r['redirect_url']) != null) {
        await openUrl(asString(r['redirect_url'])!);
      }
      if (instructions == 'manual') {
        setState(() => _phase = _Phase.manual);
        return;
      }
      if (orderId != null) _startPolling(orderId);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// No push for payments yet: ask the order until it leaves `pending`, for
  /// three minutes, as the web does.
  void _startPolling(String id) {
    setState(() => _phase = _Phase.waiting);
    final started = DateTime.now();
    _poll = Timer.periodic(const Duration(seconds: 3), (t) async {
      if (DateTime.now().difference(started).inMinutes >= 3) {
        t.cancel();
        if (mounted) setState(() => _phase = _Phase.timeout);
        return;
      }
      try {
        final o = asMap((await ref.read(apiClientProvider).getJson('/orders/$id'))['order']);
        final s = asString(o['status']);
        if (s == 'paid') {
          t.cancel();
          _done();
        } else if (s == 'failed' || s == 'expired') {
          t.cancel();
          if (!mounted) return;
          setState(() {
            _phase = _Phase.form;
            _error = 'The payment was declined or expired.';
          });
        }
      } catch (_) {}
    });
  }

  Future<void> _done() async {
    await ref.read(meProvider.notifier).refresh();
    if (mounted) setState(() => _phase = _Phase.done);
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider).valueOrNull;
    final methods = store?.methods ?? const <PaymentMethod>[];
    _method ??= methods.firstOrNull;
    final amountAfter = asDouble(_promoQuote?['amount_after']);
    final price = store?.money(amountAfter ?? widget.item.amount) ?? '';
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SheetHandle(),
            Row(children: [
              Expanded(child: Text(widget.item.label, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800))),
              if (_phase == _Phase.form) IconButton(onPressed: () => Navigator.pop(context, false), icon: const Icon(Icons.close_rounded, color: Colors.white54)),
            ]),
            Text(price, style: const TextStyle(color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.w800)),
            if (store?.anySimulated ?? false) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: .14), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withValues(alpha: .5))),
                child: const Text('Sandbox — no real money moves. Payments settle by simulation while we test.',
                    style: TextStyle(color: Colors.orange, fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
            ],
            const SizedBox(height: 16),
            ..._body(methods),
          ]),
        ),
      ),
    );
  }

  List<Widget> _body(List<PaymentMethod> methods) {
    switch (_phase) {
      case _Phase.done:
        return [
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 56),
          const SizedBox(height: 10),
          const Text('Payment received', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          PrimaryButton(label: 'Done', onPressed: () => Navigator.pop(context, true)),
        ];
      case _Phase.waiting:
        return [
          const SizedBox(height: 8),
          const Center(child: CircularProgressIndicator(color: AppColors.gold)),
          const SizedBox(height: 16),
          Text(
            _method?.needs == 'phone'
                ? 'Check your phone: approve the ${_method!.label} prompt and enter your PIN.'
                : 'Finish the payment in your browser, then come back here.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, height: 1.45),
          ),
          const SizedBox(height: 16),
          SecondaryButton(label: 'Close — I will check later', onPressed: () => Navigator.pop(context, false)),
        ];
      case _Phase.manual:
        return [
          const Text('Your order is recorded. Our team confirms manual payments and the coins land in your wallet once confirmed.',
              style: TextStyle(color: Colors.white70, height: 1.45)),
          const SizedBox(height: 16),
          PrimaryButton(label: 'OK', onPressed: () => Navigator.pop(context, false)),
        ];
      case _Phase.timeout:
        return [
          const Text('We have not heard back from the payment provider yet. If you approved it, the coins will appear shortly — check your wallet history.',
              style: TextStyle(color: Colors.white70, height: 1.45)),
          const SizedBox(height: 16),
          PrimaryButton(label: 'OK', onPressed: () => Navigator.pop(context, false)),
        ];
      case _Phase.form:
        if (methods.isEmpty) {
          return [const Text('Payments are not available in your currency yet.', style: TextStyle(color: Colors.white70))];
        }
        return [
          const Text('Pay with', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in methods) Pill(m.label, selected: _method?.id == m.id, onTap: () => setState(() {
                  _method = m;
                  _error = null;
                })),
          ]),
          if (_method?.needs == 'phone') ...[
            const SizedBox(height: 14),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Mobile money number', hintText: '2376XXXXXXXX', prefixIcon: Icon(Icons.phone_iphone_rounded, color: Colors.white38)),
            ),
          ],
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _promo,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => setState(() => _promoQuote = null),
                decoration: const InputDecoration(hintText: 'Promo code (optional)', hintStyle: TextStyle(color: Colors.white30)),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(onPressed: _busy ? null : _checkPromo, child: const Text('Apply', style: TextStyle(color: AppColors.gold))),
          ]),
          if (_promoQuote != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                (asInt(_promoQuote!['bonus_coins']) ?? 0) > 0
                    ? 'Code applied: +${_promoQuote!['bonus_coins']} bonus coins'
                    : 'Code applied',
                style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
              ),
            ),
          InlineError(_error),
          const SizedBox(height: 18),
          PrimaryButton(label: 'Pay', loading: _busy, onPressed: _pay),
        ];
    }
  }
}
