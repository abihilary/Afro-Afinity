import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/config/auth_config.dart';

class GoogleAuthUnavailable implements Exception {
  @override
  String toString() => 'Google sign-in is not set up in this build.';
}

/// Signs in with Google and hands the ID token to Supabase. Returns false if
/// the member closed the Google sheet. Supabase verifies the token against
/// the *web* client ID, so a build without `GOOGLE_WEB_CLIENT_ID` cannot work
/// and says so instead of failing with an opaque audience error.
Future<bool> signInWithGoogle() async {
  if (AuthConfig.googleWebClientId.isEmpty) throw GoogleAuthUnavailable();
  final google = GoogleSignIn(
    clientId: defaultTargetPlatform == TargetPlatform.iOS && AuthConfig.googleIosClientId.isNotEmpty
        ? AuthConfig.googleIosClientId
        : null,
    serverClientId: AuthConfig.googleWebClientId,
    scopes: const ['email', 'profile'],
  );
  final account = await google.signIn();
  if (account == null) return false;
  final auth = await account.authentication;
  final idToken = auth.idToken;
  if (idToken == null) throw Exception('Google did not return an ID token.');
  await Supabase.instance.client.auth.signInWithIdToken(
    provider: OAuthProvider.google,
    idToken: idToken,
    accessToken: auth.accessToken,
  );
  return true;
}
