import '../core/util/json.dart';

class CoinPack {
  CoinPack(Json j)
      : code = asString(j['code']) ?? '',
        coins = asInt(j['coins']) ?? 0,
        bonusCoins = asInt(j['bonus_coins']) ?? 0,
        badge = asString(j['badge']),
        price = asDouble(j['price']) ?? 0;
  final String code;
  final int coins;
  final int bonusCoins;
  final String? badge;
  final double price;
  int get total => coins + bonusCoins;
}

class TierPeriod {
  TierPeriod(Json j)
      : period = asString(j['period']) ?? 'monthly',
        price = asDouble(j['price']) ?? 0,
        coinPrice = asInt(j['coin_price']);
  final String period;
  final double price;
  final int? coinPrice;
}

class Tier {
  Tier(Json j)
      : code = asString(j['code']) ?? '',
        rank = asInt(j['rank']) ?? 0,
        labelEn = asString(j['label_en']) ?? '',
        labelFr = asString(j['label_fr']) ?? '',
        perks = asMap(j['perks']).map((k, v) => MapEntry(k, asBool(v))),
        periods = asMapList(j['periods']).map(TierPeriod.new).toList();
  final String code;
  final int rank;
  final String labelEn;
  final String labelFr;
  final Map<String, bool> perks;
  final List<TierPeriod> periods;
  String label(String locale) => locale == 'fr' ? labelFr : labelEn;
  TierPeriod? period(String p) => periods.where((x) => x.period == p).firstOrNull;
}

class GiftItem {
  GiftItem(Json j)
      : code = asString(j['code']) ?? '',
        emoji = asString(j['emoji']) ?? '🎁',
        labelEn = asString(j['label_en']) ?? '',
        labelFr = asString(j['label_fr']) ?? '',
        priceCoins = asInt(j['price_coins']) ?? 0;
  final String code;
  final String emoji;
  final String labelEn;
  final String labelFr;
  final int priceCoins;
  String label(String locale) => locale == 'fr' ? labelFr : labelEn;
}

class PaymentMethod {
  PaymentMethod(Json j)
      : id = asString(j['id']) ?? '',
        provider = asString(j['provider']) ?? '',
        needs = asString(j['needs']) ?? 'none',
        simulated = asBool(j['simulated']);
  /// mtn_momo | orange_money | card | paypal | manual
  final String id;
  final String provider;
  /// phone | redirect | none
  final String needs;
  final bool simulated;

  String get label => switch (id) {
        'mtn_momo' => 'MTN Mobile Money',
        'orange_money' => 'Orange Money',
        'card' => 'Card',
        'paypal' => 'PayPal',
        'manual' => 'Manual (sandbox)',
        _ => id,
      };
}

/// `GET /store`: everything priced, in the member's currency. The app shows
/// these numbers and sends item codes back; it never sends a price.
class Store {
  Store(Json j)
      : currency = asString(j['currency']) ?? 'XAF',
        symbol = asString(j['symbol']) ?? 'FCFA',
        decimals = asInt(j['decimals']) ?? 0,
        packs = asMapList(j['packs']).map(CoinPack.new).toList(),
        tiers = asMapList(j['tiers']).map(Tier.new).toList()..sort((a, b) => a.rank.compareTo(b.rank)),
        gifts = asMapList(j['gifts']).map(GiftItem.new).toList(),
        methods = asMapList(j['methods']).map(PaymentMethod.new).toList(),
        pricing = asMap(j['pricing']),
        custom = j['custom'] is Map ? asMap(j['custom']) : null,
        transfers = asMap(j['transfers']),
        sandbox = asBool(j['sandbox']);

  final String currency;
  final String symbol;
  final int decimals;
  final List<CoinPack> packs;
  final List<Tier> tiers;
  final List<GiftItem> gifts;
  final List<PaymentMethod> methods;
  final Json pricing;
  final Json? custom;
  final Json transfers;
  final bool sandbox;

  int get unlockCoins => asInt(pricing['unlock_coins']) ?? 30;

  /// `chat.gate_mode`: 'hard' charges [unlockCoins] to open a chat with
  /// someone you have not matched; 'soft' opens it free and allows
  /// [chatFreeMessages] before asking for the same price to continue. Never
  /// guess it: the two modes say opposite things to the member.
  bool get softGate => asString(pricing['chat_gate_mode']) == 'soft';
  int get chatFreeMessages => asInt(pricing['chat_free_messages']) ?? 5;
  int get superlikeCoins => asInt(pricing['superlike_coins']) ?? 5;
  int get boostCoins => asInt(pricing['boost_coins']) ?? 50;
  int get boostHours => asInt(pricing['boost_hours']) ?? 1;
  int get payoutMinCoins => asInt(pricing['payout_min_coins']) ?? 1000;
  double get payoutPerCoin => asDouble(pricing['payout_xaf_per_coin']) ?? 5;
  bool get transfersEnabled => asBool(transfers['enabled']);
  int get transferMin => asInt(transfers['min_coins']) ?? 10;
  bool get anySimulated => sandbox || methods.any((m) => m.simulated);

  String money(num amount) {
    final fixed = amount.toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final whole = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');
    return '${parts.length > 1 ? '$whole.${parts[1]}' : whole} $symbol';
  }

  GiftItem? gift(String code) => gifts.where((g) => g.code == code).firstOrNull;
}
