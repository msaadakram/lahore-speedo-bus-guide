import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../app/theme/app_palette.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_tokens.dart';
import '../../app/theme/theme_controller.dart';
import '../../core/services/link_launcher.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/app_widgets.dart';

/// SettingsScreen — preferences, support and legal entry points.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const website = 'https://msaadakram.me';
  static const email = 'mailto:msaadakram786@gmail.com';
  static const studio = 'https://msaadakram.me';
  static const pma = 'https://etransit.punjab.gov.pk';
  static const appVersion = 'v2.1.0 (13)';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPaletteScope.paletteOf(context);
    final theme = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppCanvas(
        child: ListView(
          key: const Key('settings-list'),
          padding: EdgeInsets.zero,
          children: [
            const AppPageHeader(
              title: 'Settings',
              subtitle: 'Manage your preferences',
              bottomRadius: 36,
            ),
            const _AppBrandCard(),
            _ThemeModeCard(
              preference: theme.preference,
              isDark: theme.isDark,
              onChanged: controller.setPreference,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                Tokens.spaceMd,
                AppSpacing.screen,
                0,
              ),
              child: Container(
                padding: const EdgeInsets.all(Tokens.spaceMd),
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(Tokens.shapeLg),
                  border: Border(
                    left: BorderSide(color: palette.accent, width: 4),
                  ),
                ),
                child: Text(
                  'This is an unofficial companion app. It is not affiliated with '
                  'Punjab Mass Transit Authority. Always confirm timings with the '
                  'operator.',
                  style: TextStyle(
                    fontSize: Tokens.fontMd,
                    height: 1.45,
                    color: palette.text,
                  ),
                ),
              ),
            ),
            const _Section(
              title: 'Contact & Support',
              items: [
                _Row(
                  icon: AppIcons.web,
                  title: 'Visit our Website',
                  subtitle: 'About the developer',
                  url: website,
                ),
                _Row(
                  icon: AppIcons.mail,
                  title: 'Email Support',
                  subtitle: 'Get in touch',
                  url: email,
                ),
                _Row(
                  icon: AppIcons.codeTags,
                  title: 'More Apps',
                  subtitle: 'Other projects',
                  url: studio,
                ),
                _Row(route: Routes.feedback, title: 'Send Feedback'),
              ],
            ),
            const _Section(
              title: 'Official Sources',
              items: [
                _Row(
                  icon: AppIcons.link,
                  title: 'Punjab Mass Transit Authority',
                  subtitle: 'etransit.punjab.gov.pk',
                  url: pma,
                ),
              ],
            ),
            const _Section(
              title: 'Legal',
              items: [
                _Row(route: Routes.privacyPolicy, title: 'Privacy Policy'),
              ],
            ),
            const _Section(
              title: 'Help & Support',
              items: [
                _Row(
                  icon: AppIcons.mail,
                  title: 'Report a Problem',
                  subtitle: 'Tell us what went wrong',
                  route: Routes.feedback,
                ),
                _Row(
                  icon: AppIcons.information,
                  title: 'How the app works',
                  subtitle: 'Offline schedules & routing',
                  dialogTitle: 'How it works',
                  dialogMessage:
                      'All routes, stops, timetables and fares are bundled with the '
                      'app, so everything works offline. Timings are estimates — '
                      'allow extra time for connections and traffic.',
                ),
                _Row(route: Routes.credits, title: 'Credits'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                Tokens.spaceLg,
                AppSpacing.screen,
                Tokens.spaceXl,
              ),
              child: Text(
                'Lahore Speedo Bus Guide · $appVersion\nOffline data · No accounts · No tracking',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Tokens.fontSm,
                  height: 1.5,
                  color: palette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBrandCard extends StatelessWidget {
  const _AppBrandCard();

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        Tokens.spaceLg,
        AppSpacing.screen,
        0,
      ),
      child: AppCard(
        radius: Tokens.shapeXl,
        elevated: true,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: palette.heroGradient,
                borderRadius: BorderRadius.circular(Tokens.shapeLg),
                boxShadow: palette.softShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Tokens.radiusLg),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  key: const Key('app-brand-logo'),
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  semanticLabel: 'Speedo Bus Route Guide logo',
                ),
              ),
            ),
            const SizedBox(width: Tokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Speedo Bus Route Guide',
                    style: TextStyle(
                      fontSize: Tokens.fontLg,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Lahore · ${SettingsScreen.appVersion}',
                    style: TextStyle(
                      fontSize: Tokens.fontSm,
                      fontWeight: FontWeight.w600,
                      color: palette.textSecondary,
                    ),
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

class _ThemeModeCard extends StatelessWidget {
  const _ThemeModeCard({
    required this.preference,
    required this.isDark,
    required this.onChanged,
  });

  final ThemePreference preference;
  final bool isDark;
  final ValueChanged<ThemePreference> onChanged;

  static const choices = <({ThemePreference value, String label})>[
    (value: ThemePreference.system, label: 'System'),
    (value: ThemePreference.light, label: 'Light'),
    (value: ThemePreference.dark, label: 'Dark'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        Tokens.spaceLg,
        AppSpacing.screen,
        0,
      ),
      child: AppCard(
        radius: Tokens.shapeXl,
        elevated: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(Tokens.shapeSm),
                  ),
                  child: Icon(
                    AppIcons.themeLightDark,
                    size: 20,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(width: Tokens.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Appearance',
                        style: TextStyle(
                          fontSize: Tokens.fontBase,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isDark
                            ? 'Dark theme is active'
                            : 'Light theme is active',
                        style: TextStyle(
                          fontSize: Tokens.fontSm,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Tokens.spaceMd),
            Row(
              children: [
                for (final choice in choices) ...[
                  if (choice.value != choices.first.value)
                    const SizedBox(width: Tokens.spaceSm),
                  Expanded(
                    child: _ThemeChoice(
                      label: choice.label,
                      selected: preference == choice.value,
                      onTap: () => onChanged(choice.value),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return AppPressable(
      onPressed: onTap,
      selected: selected,
      semanticLabel: '$label theme',
      borderRadius: BorderRadius.circular(Tokens.shapePill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? palette.primary : palette.surfaceTint,
          borderRadius: BorderRadius.circular(Tokens.shapePill),
          border: Border.all(
            color: selected ? palette.primary : palette.border,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: Tokens.fontSm,
            fontWeight: FontWeight.w800,
            color: selected ? palette.onPrimary : palette.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Opens an external URI and reports an obvious failure instead of doing
/// nothing when the device has no handler.
Future<void> _openLinkWithContext(BuildContext context, String url) async {
  final opened = await openLink(url);
  if (opened || !context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Could not open the link.')));
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});

  final String title;
  final List<_Row> items;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        Tokens.spaceXl,
        AppSpacing.screen,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            text: title.toUpperCase(),
            margin: const EdgeInsets.only(bottom: Tokens.spaceSm),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            radius: Tokens.shapeXl,
            elevated: true,
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i != 0)
                    Divider(height: 1, thickness: 1, color: palette.border),
                  items[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    this.icon,
    required this.title,
    this.subtitle,
    this.route,
    this.url,
    this.dialogTitle,
    this.dialogMessage,
  });

  final IconData? icon;
  final String title;
  final String? subtitle;
  final String? route;
  final String? url;
  final String? dialogTitle;
  final String? dialogMessage;

  VoidCallback? _onTap(BuildContext context) {
    if (route != null) {
      return () => Navigator.of(context).pushNamed(route!);
    }
    if (url != null) {
      return () => _openLinkWithContext(context, url!);
    }
    if (dialogTitle != null && dialogMessage != null) {
      return () => showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(dialogTitle!),
          content: Text(dialogMessage!),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final onTap = _onTap(context);
    final effectiveIcon =
        icon ??
        switch (route) {
          Routes.feedback => AppIcons.mail,
          Routes.privacyPolicy => AppIcons.shield,
          Routes.credits => AppIcons.information,
          _ => AppIcons.chevronRight,
        };

    return AppPressable(
      onPressed: onTap,
      borderRadius: BorderRadius.circular(Tokens.shapeLg),
      child: Padding(
        padding: const EdgeInsets.all(Tokens.spaceMd),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(Tokens.shapeSm),
              ),
              child: Icon(effectiveIcon, size: 18, color: palette.primary),
            ),
            const SizedBox(width: Tokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: Tokens.fontBase,
                      fontWeight: FontWeight.w700,
                      color: palette.text,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: Tokens.fontSm,
                        height: 1.35,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                AppIcons.chevronRight,
                size: 18,
                color: palette.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
