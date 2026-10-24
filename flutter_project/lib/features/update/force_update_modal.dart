import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_tokens.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/app_widgets.dart';

/// ForceUpdateModal (Metro module 1079) + the in-app update trigger from
/// `AppShell` (module 495, `sp-react-native-in-app-update`).
class ForceUpdateModal extends StatelessWidget {
  const ForceUpdateModal({
    required this.visible,
    required this.onUpdate,
    this.storeVersion,
    super.key,
  });

  final bool visible;
  final VoidCallback onUpdate;
  final String? storeVersion;

  static const _packageId = 'com.msaadakram.lahorebus';

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final palette = AppPaletteScope.paletteOf(context);

    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.black54,
        child: SafeArea(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(Tokens.spaceXl),
              padding: const EdgeInsets.all(Tokens.spaceXl),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(Tokens.radiusXl),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    AppIcons.alertTriangle,
                    size: 40,
                    color: Color(0xFF1A73E8),
                  ),
                  const SizedBox(height: Tokens.spaceMd),
                  Text(
                    'Update available',
                    style: TextStyle(
                      fontSize: Tokens.fontXl,
                      fontWeight: FontWeight.w800,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: Tokens.spaceSm),
                  Text(
                    'A new version of Lahore Speedo Bus Guide is available on the '
                    'Play Store${storeVersion == null ? '' : ' (version $storeVersion)'}. '
                    'Please update to keep using the latest routes and timings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: Tokens.fontMd,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Tokens.spaceXl),
                  AppButton(
                    label: 'Update Now',
                    icon: AppIcons.reload,
                    onPressed: onUpdate,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the Play Store listing — the same destination as
  /// `IAUUpdateKind.IMMEDIATE` + `startUpdate` in the original.
  static Future<void> openStore() async {
    final uri = Uri.parse('market://details?id=$_packageId');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(
        Uri.parse('https://play.google.com/store/apps/details?id=$_packageId'),
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
