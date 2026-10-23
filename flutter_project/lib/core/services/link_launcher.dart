import 'package:url_launcher/url_launcher.dart';

/// `Linking.openURL` equivalent.
Future<void> openLink(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
