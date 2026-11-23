import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get supabase => Supabase.instance.client;

/// The signed-in Supabase session, or null. Also keeps the realtime socket
/// authenticated: an anonymous socket passes RLS as nobody and silently
/// delivers zero rows, so the token is re-set on every refresh.
final sessionProvider = StreamProvider<Session?>((ref) {
  final controller = StreamController<Session?>();
  controller.add(supabase.auth.currentSession);
  _setRealtimeAuth(supabase.auth.currentSession);
  final sub = supabase.auth.onAuthStateChange.listen((state) {
    _setRealtimeAuth(state.session);
    controller.add(state.session);
  });
  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });
  return controller.stream;
});

/// Just the user id, so a token refresh (same user, new JWT) does not make
/// everything downstream refetch.
final userIdProvider = Provider<String?>((ref) {
  return ref.watch(sessionProvider.select((s) => s.valueOrNull?.user.id)) ??
      supabase.auth.currentSession?.user.id;
});

void _setRealtimeAuth(Session? s) {
  if (s != null) supabase.realtime.setAuth(s.accessToken);
}

/// Ends the Supabase session. Every provider keyed on [userIdProvider]
/// resets itself, and the router's redirect takes the member to sign-in.
Future<void> signOut() async {
  try {
    await supabase.auth.signOut();
  } catch (_) {
    // A dead refresh token still signs out locally.
    await supabase.auth.signOut(scope: SignOutScope.local);
  }
}
