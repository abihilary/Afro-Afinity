import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/config/auth_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AuthConfig.supabaseUrl,
    publishableKey: AuthConfig.supabaseAnonKey,
  );

  final session = Supabase.instance.client.auth.currentSession;
  debugPrint('Main: Initial session found: ${session != null}');
  if (session != null) {
    debugPrint('Main: Session user: ${session.user.email}');
  }

  runApp(
    const ProviderScope(
      child: AfricanAffinityApp(),
    ),
  );
}
