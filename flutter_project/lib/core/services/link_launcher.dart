import 'package:url_launcher/url_launcher.dart';

/// `Linking.openURL` equivalent.
///
/// Returns `false` when the platform has no handler for the URI so callers can
/// surface a message instead of failing silently.
Future<bool> openLink(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
