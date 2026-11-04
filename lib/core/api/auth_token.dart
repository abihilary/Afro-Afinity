import 'package:supabase_flutter/supabase_flutter.dart';

String? currentAccessToken() {
  return Supabase.instance.client.auth.currentSession?.accessToken;
}
