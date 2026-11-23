import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/me.dart';
import '../../models/profile_options.dart';
import '../../models/store.dart';
import '../api/api_client.dart';
import '../util/json.dart';
import 'session.dart';

/// `GET /me`, cached for the whole app. Null when signed out. Any call that
/// returns the fresh self (PATCH /me, PUT /me/photos, /me/boost, …) hands it
/// to [MeNotifier.replace] instead of refetching.
class MeNotifier extends AsyncNotifier<Me?> {
  @override
  Future<Me?> build() async {
    final uid = ref.watch(userIdProvider);
    if (uid == null) return null;
    final json = await ref.read(apiClientProvider).getJson('/me');
    return Me(json);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async => Me(await ref.read(apiClientProvider).getJson('/me')));
  }

  void replace(Object? json) {
    if (json is Map) state = AsyncData(Me(asMap(json)));
  }

  /// PATCH /me with a partial body; the response is the new self.
  Future<Me> patch(Map<String, dynamic> body) async {
    final json = await ref.read(apiClientProvider).patch('/me', data: body);
    replace(json);
    return state.requireValue!;
  }

  /// Keep the wallet in step after a spend, without a round trip.
  void setBalance(int balance) {
    final me = state.valueOrNull;
    if (me == null) return;
    final raw = Map<String, dynamic>.of(me.raw);
    raw['wallet'] = {...asMap(raw['wallet']), 'balance': balance};
    state = AsyncData(Me(raw));
  }
}

final meProvider = AsyncNotifierProvider<MeNotifier, Me?>(MeNotifier.new);

/// The member's own store, in their currency. Public, but signed-in callers
/// get their own currency, so it is re-read when the user changes.
final storeProvider = FutureProvider<Store>((ref) async {
  ref.watch(userIdProvider);
  return Store(await ref.read(apiClientProvider).getJson('/store'));
});

final profileOptionsProvider = FutureProvider<ProfileOptions>((ref) async {
  return ProfileOptions(await ref.read(apiClientProvider).getJson('/profile-options'));
});

/// Public settings: support contacts, limits.
final configProvider = FutureProvider<Json>((ref) async {
  return asMap((await ref.read(apiClientProvider).getJson('/config'))['settings']);
});

/// The member's locale, for option labels.
final localeProvider = Provider<String>((ref) => ref.watch(meProvider).valueOrNull?.locale ?? 'en');
