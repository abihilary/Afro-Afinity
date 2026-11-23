import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/config/auth_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: AuthConfig.supabaseUrl, publishableKey: AuthConfig.supabaseAnonKey);
  runApp(const ProviderScope(child: AfricanAffinityApp()));
}
