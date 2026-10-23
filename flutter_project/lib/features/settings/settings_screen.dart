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

/// SettingsScreen (Metro module 737).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const website = 'https://msaadakram.me';
  static const email = 'mailto:msaadakram786@gmail.com';
  static const studio = 'https://msaadakram.me';
  static const pma = 'https://etransit.punjab.gov.pk';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPaletteScope.paletteOf(context);
    final theme = ref.watch(themeControllerProvider);
    final darkMode = theme.isDark;

    return Scaffold(
      body: ColoredBox(
        color: palette.background,
        child: ListView(
          key: const Key('settings-list'),
          padding: EdgeInsets.zero,
          children: [
            const AppPageHeader(
              title: 'Settings',
              subtitle: 'Manage your preferences',
            ),

            // Dark Mode
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                Tokens.spaceLg,
                AppSpacing.screen,
                0,
              ),
              child: AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: palette.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(Tokens.radiusSm),
                      ),
                      child: const Icon(
                        AppIcons.themeLightDark,
                        size: 18,
                        color: Color(0xFF3B7306),
                      ),
                    ),
                    const SizedBox(width: Tokens.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dark Mode',
                            style: TextStyle(
                              fontSize: Tokens.fontBase,
                              fontWeight: FontWeight.w700,
                              color: palette.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            darkMode ? 'Currently on' : 'Currently off',
                            style: TextStyle(
                              fontSize: Tokens.fontSm,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: darkMode,
                      onChanged: (_) => ref
                          .read(themeControllerProvider.notifier)
                          .toggleTheme(),
                    ),
                  ],
                ),
              ),
            ),

            // Unofficial disclaimer
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
                  color: palette.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(Tokens.radiusLg),
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
                    color: palette.text,
                  ),
                ),
              ),
            ),

            _Section(
              title: 'Contact & Support',
              items: [
                _Row(
                  icon: AppIcons.web,
                  title: 'Visit our Website',
                  subtitle: 'About the developer',
                  onTap: () => openLink(website),
                ),
                _Row(
                  icon: AppIcons.mail,
                  title: 'Email Support',
                  subtitle: 'Get in touch',
                  onTap: () => openLink(email),
                ),
                _Row(
                  icon: AppIcons.codeTags,
                  title: 'More Apps',
                  subtitle: 'Other projects',
                  onTap: () => openLink(studio),
                ),
                _Row(
                  icon: AppIcons.mail,
                  title: 'Send Feedback',
                  subtitle: 'Complaint, suggestion, bug report & more',
                  onTap: () => Navigator.of(context).pushNamed(Routes.feedback),
                ),
              ],
            ),

            _Section(
              title: 'Official Sources',
              items: [
                _Row(
                  icon: AppIcons.link,
                  title: 'Punjab Mass Transit Authority',
                  subtitle: 'etransit.punjab.gov.pk',
                  onTap: () => openLink(pma),
                ),
              ],
            ),

            _Section(
              title: 'Legal',
              items: [
                _Row(
                  icon: AppIcons.shield,
                  title: 'Privacy Policy',
                  subtitle: 'How your data is handled',
                  onTap: () => Navigator.of(context).pushNamed(Routes.privacyPolicy),
                ),
              ],
            ),

            _Section(
              title: 'Help & Support',
              items: [
                _Row(
                  icon: AppIcons.mail,
                  title: 'Report a Problem',
                  subtitle: 'Tell us what went wrong',
                  onTap: () => Navigator.of(context).pushNamed(Routes.feedback),
                ),
                _Row(
                  icon: AppIcons.information,
                  title: 'How the app works',
                  subtitle: 'Offline schedules & routing',
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('How it works'),
                      content: const Text(
                        'All routes, stops, timetables and fares are bundled with the '
                        'app, so everything works offline. Timings are estimates — '
                        'allow extra time for connections and traffic.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  ),
                ),
                _Row(
                  icon: AppIcons.mail,
                  title: 'Credits',
                  subtitle: 'The team behind the app',
                  onTap: () => Navigator.of(context).pushNamed(Routes.credits),
                ),
              ],
            ),

            const SizedBox(height: Tokens.spaceXxl),
          ],
        ),
      ),
    );
  }
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
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return AppPressable(
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.all(Tokens.spaceMd),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Tokens.radiusSm),
              ),
              child: Icon(icon, size: 18, color: palette.primary),
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
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: Tokens.fontSm,
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
