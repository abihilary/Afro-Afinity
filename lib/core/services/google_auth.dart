import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/config/auth_config.dart';

class GoogleAuthUnavailable implements Exception {
  @override
  String toString() => 'Google sign-in is not available right now. Please use your email and password.';
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
  final GoogleSignInAccount? account;
  try {
    account = await google.signIn();
  } on PlatformException catch (e) {
    // sign_in_failed / ApiException 10 means this package + signing key is not
    // registered as an Android OAuth client in Google Cloud. Say so in the
    // log; show the member something they can act on.
    debugPrint('Google sign-in failed: ${e.code} ${e.message}');
    throw GoogleAuthUnavailable();
  }
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
