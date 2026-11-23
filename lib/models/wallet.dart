import '../core/util/json.dart';
import 'member.dart';

class LedgerEntry {
  LedgerEntry(Json j)
      : id = asString(j['id']) ?? '',
        delta = asInt(j['delta']) ?? 0,
        kind = asString(j['kind']) ?? '',
        meta = asMap(j['meta']),
        createdAt = asDate(j['created_at']),
        counterpart = j['counterpart'] is Map ? MemberCard(asMap(j['counterpart'])) : null;
  final String id;
  final int delta;
  final String kind;
  final Json meta;
  final DateTime? createdAt;
  final MemberCard? counterpart;

  String get label => switch (kind) {
        'purchase' => 'Coins bought',
        'gift_sent' => 'Gift sent',
        'gift_received' => 'Gift received',
        'unlock' => 'Chat unlocked',
        'superlike' => 'Super like',
        'boost' => 'Boost',
        'transfer_in' => 'Coins received',
        'transfer_out' => 'Coins sent',
        'payout' => 'Payout',
        'subscription' => 'Plan paid with coins',
        'message_quota' => 'More messages',
        'adjustment' => 'Adjustment',
        'refund' => 'Refund',
        _ => kind.replaceAll('_', ' '),
      };
}

class Order {
  Order(Json j)
      : id = asString(j['id']) ?? '',
        kind = asString(j['kind']) ?? '',
        itemCode = asString(j['item_code']) ?? '',
        period = asString(j['period']),
        amount = asDouble(j['amount']) ?? 0,
        currency = asString(j['currency']) ?? '',
        status = asString(j['status']) ?? 'pending',
        createdAt = asDate(j['created_at']);
  final String id;
  final String kind;
  final String itemCode;
  final String? period;
  final double amount;
  final String currency;
  /// pending | paid | failed | refunded …
  final String status;
  final DateTime? createdAt;
}

class Transfer {
  Transfer(Json j)
      : id = asString(j['id']) ?? '',
        coins = asInt(j['coins']) ?? 0,
        note = asString(j['note']),
        outgoing = asString(j['direction']) == 'out',
        createdAt = asDate(j['created_at']),
        counterpart = j['counterpart'] is Map ? MemberCard(asMap(j['counterpart'])) : null;
  final String id;
  final int coins;
  final String? note;
  final bool outgoing;
  final DateTime? createdAt;
  final MemberCard? counterpart;
}

class Payout {
  Payout(Json j)
      : id = asString(j['id']) ?? '',
        coins = asInt(j['coins']) ?? 0,
        status = asString(j['status']) ?? 'pending',
        momo = asString(j['momo_number']),
        amount = asDouble(j['amount_xaf'] ?? j['amount']),
        createdAt = asDate(j['created_at']);
  final String id;
  final int coins;
  final String status;
  final String? momo;
  final double? amount;
  final DateTime? createdAt;
}
