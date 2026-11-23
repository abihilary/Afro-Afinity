/// Supabase is used for exactly two things: minting the session the API
/// trusts, and the realtime chat socket. The publishable key is public by
/// design; RLS protects the data.
class AuthConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ymmfduvnwzejrpoqwpmf.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InltbWZkdXZud3planJwb3F3cG1mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk1NTAwNjAsImV4cCI6MjEwNTEyNjA2MH0.RrbPeamB8I_9IiFaUw0copNkFolP7uE_YWhl4eUf6EI',
  );

  /// Google sign-in: the *web* client ID is the server client ID that
  /// Supabase verifies the ID token against.
  ///
  /// This is the same web client the website's Google button uses (Supabase
  /// reads it from its Google provider), so tokens minted for it are accepted.
  /// It is a public identifier, not a secret. Android additionally needs an
  /// *Android* OAuth client in the same Google Cloud project for this package
  /// and signing key; see README.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '663237549190-9e2dvcjfh5p3chv1gv7ge5vhtin6djil.apps.googleusercontent.com',
  );
  /// False only if a build blanks the client ID out (`--dart-define=GOOGLE_WEB_CLIENT_ID=`):
  /// the buttons then hide rather than offer a sign-in that cannot work.
  static bool get googleEnabled => googleWebClientId.isNotEmpty;
  static const String googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
}
