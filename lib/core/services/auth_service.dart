import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> logout() async {
    state = const AsyncValue.data(null);
  }
}

final authServiceProvider =
    AsyncNotifierProvider<AuthService, void>(AuthService.new);
