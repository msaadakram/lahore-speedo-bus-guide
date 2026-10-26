import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_tokens.dart';
import '../../core/services/link_launcher.dart';
import '../../shared/widgets/app_widgets.dart';

/// PrivacyPolicyScreen — a first-class, in-app privacy policy so the store
/// listing never depends on an external URL being reachable.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const contactEmail = 'msaadakram786@gmail.com';
  static const developerSite = 'https://msaadakram.me';

  static const String updated = 'October 23, 2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppCanvas(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const AppPageHeader(
              title: 'Privacy Policy',
              subtitle: 'Last updated $updated',
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screen,
                Tokens.spaceLg,
                AppSpacing.screen,
                Tokens.spaceXxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Paragraph(
                    'Lahore Speedo Bus Guide ('
                    'Lahore Electric Bus Guide'
                    ') '
                    'helps you find routes, stops and schedules for the '
                    'Lahore bus network. It is built and maintained by '
                    'Muhammad Saad — no company, server or analytics '
                    'platform in between.',
                  ),
                  _Paragraph(
                    'This policy explains exactly what the app does — and '
                    'does not — do with your data.',
                  ),
                  _Section(
                    title: '1. Your Data — Simplicity',
                    children: [
                      _Paragraph(
                        'The app does not collect, store, sell, or share any '
                        'personal information. There are:',
                      ),
                      _Bullet('no user accounts or sign-up'),
                      _Bullet('no analytics or crash-reporting SDKs'),
                      _Bullet('no advertising or ad identifiers'),
                      _Bullet(
                        'no tracking across apps, sites or offline activity',
                      ),
                    ],
                  ),
                  _Section(
                    title: '2. Location',
                    children: [
                      _Paragraph(
                        'The Nearby screen can show stops close to you. '
                        'Location is requested only when you tap to find '
                        'stops, is processed only on your device to compute '
                        'distances, and is never stored, logged or sent to '
                        'us. If you deny the permission the app keeps '
                        'working with every other feature.',
                      ),
                    ],
                  ),
                  _Section(
                    title: '3. Maps and map tiles',
                    children: [
                      _Paragraph(
                        'Map screens fetch map imagery from OpenStreetMap '
                        'when the map is open. Your device contacts '
                        'OpenStreetMap servers directly; what they see '
                        '(like your IP address and map area) is governed by '
                        'their own policy. We do not proxy, store or view '
                        'those requests.',
                      ),
                      _LinkLine(
                        'OpenStreetMap Foundation privacy policy: '
                            'https://osmfoundation.org/wiki/Privacy_Policy',
                        'https://osmfoundation.org/wiki/Privacy_Policy',
                      ),
                    ],
                  ),
                  _Section(
                    title: '4. Bus data',
                    children: [
                      _Paragraph(
                        'Routes, stops and timetables are bundled inside the '
                        'app and reference the public network of Punjab '
                        'Mass Transit Authority (etransit.punjab.gov.pk). '
                        'Searching happens entirely on your device.',
                      ),
                    ],
                  ),
                  _Section(
                    title: '5. Feedback',
                    children: [
                      _Paragraph(
                        'The in-app form is optional. If you submit it, only '
                        'the details you typed (name, message, and, if you '
                        'enter one, an email address) are sent so the '
                        'developer can reply. Nothing is attached silently '
                        'and nothing is used for marketing.',
                      ),
                    ],
                  ),
                  _Section(
                    title: '6. Children',
                    children: [
                      _Paragraph(
                        'The app does not knowingly collect any data from '
                        'anyone, including children under 13.',
                      ),
                    ],
                  ),
                  _Section(
                    title: '7. Links',
                    children: [
                      _Paragraph(
                        'The app links to official sources and the '
                        'developer site. Those sites have their own '
                        'policies, which the app cannot control.',
                      ),
                    ],
                  ),
                  _Section(
                    title: '8. Changes to this policy',
                    children: [
                      _Paragraph(
                        'If the app ever adds a feature that touches personal '
                        'data, this page changes, and the app shows the '
                        'updated policy in Settings → Privacy Policy.',
                      ),
                    ],
                  ),
                  _Section(
                    title: '9. Contact',
                    children: [
                      _Paragraph(
                        'Questions, requests or data concerns are welcome — '
                        'the developer answers email directly.',
                      ),
                      _LinkLine(
                        'msaadakram786@gmail.com',
                        'mailto:msaadakram786@gmail.com?'
                            'subject=Lahore%20Speedo%20Bus%20Guide',
                      ),
                      _LinkLine('msaadakram.me', developerSite),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openLinkWithContext(BuildContext context, String url) async {
  final opened = await openLink(url);
  if (opened || !context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Could not open the link.')));
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: Tokens.spaceLg),
      child: AppCard(
        padding: const EdgeInsets.all(Tokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: Tokens.fontLg,
                fontWeight: FontWeight.w800,
                color: palette.primary,
              ),
            ),
            const SizedBox(height: Tokens.spaceMd),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Tokens.spaceSm),
      child: Text(
        text,
        style: TextStyle(
          fontSize: Tokens.fontBase,
          height: 1.55,
          color: palette.text,
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: Tokens.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: TextStyle(
              fontSize: Tokens.fontBase,
              height: 1.55,
              color: palette.primary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: Tokens.fontBase,
                height: 1.55,
                color: palette.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable line inside a policy section (email or link).
class _LinkLine extends StatelessWidget {
  const _LinkLine(this.text, this.url);

  final String text;
  final String url;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: AppPressable(
        onPressed: () => _openLinkWithContext(context, url),
        child: Text(
          text,
          style: TextStyle(
            fontSize: Tokens.fontBase,
            height: 1.55,
            color: palette.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
