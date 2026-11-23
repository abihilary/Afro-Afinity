import 'dart:convert';
import 'dart:io';

import 'package:african_affinity/core/api/api_client.dart';
import 'package:african_affinity/core/ui/api_errors.dart';
import 'package:african_affinity/core/util/json.dart';
import 'package:african_affinity/features/discover/filters.dart';
import 'package:african_affinity/models/conversation.dart';
import 'package:african_affinity/models/me.dart';
import 'package:african_affinity/models/member.dart';
import 'package:african_affinity/models/message.dart';
import 'package:african_affinity/models/profile_options.dart';
import 'package:african_affinity/models/store.dart';
import 'package:african_affinity/models/wallet.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixtures are real responses captured from the local API (seed data only).
Json fx(String name) => jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Json;

void main() {
  group('models parse real API payloads', () {
    test('/me', () {
      final me = Me(fx('me'));
      expect(me.username, 'woman_a');
      expect(me.status, MemberStatus.active);
      expect(me.canInteract, isTrue);
      expect(me.photos, isNotEmpty);
      expect(me.photos.first.url, startsWith('http'));
      expect(me.balance, 32);
      expect(me.perks.seeLikes, isFalse);
      expect(me.age, greaterThanOrEqualTo(18));
      expect(me.completion, inInclusiveRange(0, 100));
    });

    test('an unverified member cannot interact', () {
      final raw = {...fx('me'), 'verified_at': null, 'status': 'pending'};
      expect(Me(raw).canInteract, isFalse);
    });

    test('/discover cards', () {
      final items = asMapList(fx('discover_limit_2')['items']).map(MemberCard.new).toList();
      expect(items, isNotEmpty);
      expect(items.first.userId, isNotEmpty);
      expect(items.first.avatarUrl, startsWith('http'));
    });

    test('/profiles/:username', () {
      final p = PublicProfile(fx('profiles_man_b'));
      expect(p.card.username, 'man_b');
      expect(p.teaser, isFalse);
      expect(p.photos, isNotEmpty);
    });

    test('/conversations', () {
      final c = Conversation(asMapList(fx('conversations')['items']).first);
      expect(c.id, isNotEmpty);
      expect(c.other.name, 'Mo');
      expect(c.unread, 4);
    });

    test('blurred views keep the server redaction', () {
      final row = ConnectionRow(asMapList(fx('views_received')['items']).first);
      expect(row.member.blurred, isTrue);
      expect(row.member.username, isNull);
      expect(row.viewCount, 24);
    });

    test('/gifts rows carry the person and the gift', () {
      final row = ConnectionRow(asMapList(fx('gifts_direction_in')['items']).first);
      expect(row.member.name, 'Mo');
      expect(row.giftEmoji, '🌹');
      expect(row.coins, 10);
    });

    test('/store', () {
      final s = Store(fx('store'));
      expect(s.currency, 'XAF');
      expect(s.packs.map((p) => p.code), contains('starter'));
      expect(s.tiers.map((t) => t.code), ['gold', 'platinum']);
      expect(s.tiers.last.perks['advanced_search'], isTrue);
      expect(s.gifts.first.code, 'rose');
      expect(s.methods.first.needs, 'phone');
      expect(s.anySimulated, isTrue);
      expect(s.money(4500), '4 500 FCFA');
    });

    test('/me/ledger', () {
      final e = LedgerEntry(asMapList(fx('me_ledger')['items']).first);
      expect(e.kind, 'gift_received');
      expect(e.delta, 8);
      expect(e.counterpart?.name, 'Mo');
    });

    test('/profile-options', () {
      final o = ProfileOptions(fx('profile-options'));
      expect(o.of('eye_color'), isNotEmpty);
      expect(o.labelFor('eye_color', 'black', 'fr'), 'Noirs');
    });

    test('messages decide ownership from sender when the row has no "mine"', () {
      final m = Message.fromJson({'id': '1', 'sender_id': 'me', 'body': 'hi', 'created_at': '2026-11-01T10:00:00Z'}, myId: 'me');
      expect(m.mine, isTrue);
      final n = Message.fromJson({'id': '2', 'sender_id': 'x', 'body': 'yo', 'created_at': '2026-11-01T10:00:00Z', 'mine': false}, myId: 'me');
      expect(n.mine, isFalse);
    });
  });

  group('filters', () {
    test('discover query carries only the free keys', () {
      const f = SearchFilters(minAge: 25, maxAge: 40, online: true, interests: {'jazz'}, goal: 'marriage');
      final q = f.toDiscoverQuery();
      expect(q['min_age'], 25);
      expect(q['online'], 'true');
      expect(q['interests'], 'jazz');
      expect(q.containsKey('goal'), isFalse);
    });

    test('search body includes advanced keys and round-trips', () {
      const f = SearchFilters(goal: 'marriage', languages: {'fr'}, attrs: {'smoker': 'no'});
      expect(f.hasAdvanced, isTrue);
      final back = SearchFilters.fromJson(f.toSearchFilters());
      expect(back.goal, 'marriage');
      expect(back.languages, {'fr'});
      expect(back.attrs['smoker'], 'no');
    });
  });

  group('error text', () {
    ApiException e(String code, [Json details = const {}]) => ApiException(code: code, message: 'raw', details: details, statusCode: 400);

    test('daily_limit shows the cap', () => expect(errorText(e('daily_limit', {'cap': 30})), contains('30')));
    test('offline is not "something went wrong"', () => expect(errorText(NetworkException('x')), contains('offline')));
    test('incomplete lists what is missing', () => expect(errorText(e('incomplete', {'missing': ['city', 'photos']})), contains('city, photos')));
    test('unknown codes fall back to the server message', () => expect(errorText(e('weird_code')), 'raw'));
  });
}
