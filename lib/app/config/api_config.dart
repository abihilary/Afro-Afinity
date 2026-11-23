/// Build-time configuration. One binary targets either environment:
///
///   flutter run --dart-define-from-file=config/local.json
///
/// See config/example.json for the keys.
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.affroafinity.mambandamarket.com',
  );

  /// Where the website lives, for legal pages and links out.
  static const String webUrl = String.fromEnvironment(
    'WEB_URL',
    defaultValue: 'https://affroafinity.mambandamarket.com',
  );
}
