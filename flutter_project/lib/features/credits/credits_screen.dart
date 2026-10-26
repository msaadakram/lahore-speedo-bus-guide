import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_tokens.dart';
import '../../core/services/link_launcher.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/app_widgets.dart';

/// CreditsScreen — the developer behind the app (Metro module 1081).
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppCanvas(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const AppPageHeader(
              title: 'Credits',
              subtitle: 'Who built and maintains this app',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                Tokens.spaceXl,
                AppSpacing.screen,
                0,
              ),
              child: Column(
                children: [
                  _CreditCard(
                    accent: palette.primary,
                    initials: 'MS',
                    name: 'Muhammad Saad',
                    role: 'DEVELOPER & MAINTAINER',
                    description: 'Flutter & Web Developer',
                    tags: [
                      'Flutter Apps',
                      'Routing & Data',
                      'More projects on msaadakram.me',
                    ],
                    url: 'https://msaadakram.me',
                  ),
                ],
              ),
            ),
            const SizedBox(height: Tokens.spaceXxl),
          ],
        ),
      ),
    );
  }
}

class _CreditCard extends StatelessWidget {
  const _CreditCard({
    required this.accent,
    required this.initials,
    required this.name,
    required this.role,
    required this.description,
    required this.tags,
    required this.url,
  });

  final Color accent;
  final String initials;
  final String name;
  final String role;
  final String description;
  final List<String> tags;
  final String url;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return AppCard(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.30)),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: Tokens.fontXl,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: Tokens.spaceMd),
          Text(
            role,
            style: TextStyle(
              fontSize: Tokens.fontXs,
              fontWeight: FontWeight.w800,
              color: accent,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Tokens.fontXl,
              fontWeight: FontWeight.w800,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Tokens.fontSm,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: Tokens.spaceMd),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: tags
                .map(
                  (t) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Tokens.spaceSm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: palette.background,
                      borderRadius: BorderRadius.circular(Tokens.radiusFull),
                      border: Border.all(color: palette.border),
                    ),
                    child: Text(
                      t,
                      style: TextStyle(
                        fontSize: Tokens.fontXs,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: Tokens.spaceMd),
          AppPressable(
            onPressed: () async {
              final opened = await openLink(url);
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('Could not open the link.')),
                  );
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Tokens.radiusMd),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(AppIcons.link, size: 16, color: accent),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Visit msaadakram.me',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Tokens.fontSm,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
