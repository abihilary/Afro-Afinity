import 'package:url_launcher/url_launcher.dart';

import '../../app/config/api_config.dart';

/// Opens a page of the website (legal pages, safety) in the browser.
Future<void> openWeb(String path) => launchUrl(Uri.parse('${ApiConfig.webUrl}$path'), mode: LaunchMode.externalApplication);

Future<void> openUrl(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
