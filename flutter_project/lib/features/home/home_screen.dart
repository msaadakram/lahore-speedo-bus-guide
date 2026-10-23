import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../app/theme/app_palette.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_tokens.dart';
import '../../data/models/bus_stop.dart';
import '../../features/stop_picker/stop_picker_screen.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/route_widgets.dart';

/// RouteFinderScreen — the "Home" tab (Metro module 569).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  BusStop? _from;
  BusStop? _to;

  bool get _canSearch => _from != null && _to != null && _from!.id != _to!.id;

  void _swap() {
    setState(() {
      final tmp = _from;
      _from = _to;
      _to = tmp;
    });
  }

  Future<void> _openPicker(String mode) async {
    final picked = await Navigator.of(context).push<BusStop>(
      MaterialPageRoute(
        settings: const RouteSettings(name: Routes.stopPicker),
        builder: (_) => StopPickerScreen(mode: mode),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (mode == 'from') {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final insets = MediaQuery.paddingOf(context);

    return Scaffold(
      body: ColoredBox(
        color: palette.background,
        child: Column(
          children: [
            // ------------------------------------------------------ header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: palette.heroGradient,
                boxShadow: palette.softShadow,
              ),
              padding: EdgeInsets.only(
                left: AppSpacing.screen,
                right: AppSpacing.screen,
                top: insets.top + Tokens.spaceMd,
                bottom: Tokens.spaceXl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lahore 🇵🇰',
                        style: TextStyle(
                          fontSize: Tokens.fontLg,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      AppPressable(
                        onPressed: () =>
                            Navigator.of(context).pushNamed(Routes.search),
                        borderless: true,
                        rippleColor: Colors.white,
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            AppIcons.magnify,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Tokens.spaceLg),
                  const Text(
                    'Every route, one tap away!',
                    style: TextStyle(
                      fontSize: Tokens.fontXl,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 40 / 22,
                    ),
                  ),
                  const SizedBox(height: Tokens.spaceSm),
                  const Wrap(
                    spacing: Tokens.spaceSm,
                    runSpacing: Tokens.spaceXs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TagChip(
                        label: 'Speedo',
                        asset: 'assets/images/speedo.jpg',
                      ),
                      TagChip(label: 'Metro', asset: 'assets/images/metro.jpg'),
                      TagChip(
                        label: 'Electric',
                        asset: 'assets/images/electric.jpg',
                      ),
                      TagChip(
                        label: 'Orange Line',
                        asset: 'assets/images/orangeline.jpg',
                        last: true,
                      ),
                      TagChip(
                        label: 'Offline',
                        icon: AppIcons.wifiOff,
                        last: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ------------------------------------------------------ scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: Tokens.spaceXl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Journey planner card
                    Container(
                      margin: const EdgeInsets.all(Tokens.spaceMd),
                      padding: const EdgeInsets.all(Tokens.spaceSm),
                      decoration: BoxDecoration(
                        color: palette.card,
                        borderRadius: BorderRadius.circular(Tokens.shapeLg),
                        border: Border.all(color: palette.border),
                        boxShadow: palette.softShadow,
                      ),
                      child: Column(
                        children: [
                          _StopField(
                            label: 'FROM',
                            accent: const Color(0xFFF08C00),
                            icon: AppIcons.mapMarker,
                            value: _from?.name,
                            placeholder: 'From — pick a stop',
                            onTap: () => _openPicker('from'),
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: 34,
                                child: Center(
                                  child: SizedBox(
                                    width: 1,
                                    height: Tokens.spaceMd,
                                    child: ColoredBox(color: palette.border),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _StopField(
                                        label: 'TO',
                                        accent: const Color(0xFF2E7D32),
                                        icon: AppIcons.flag,
                                        value: _to?.name,
                                        placeholder: 'To — pick a stop',
                                        onTap: () => _openPicker('to'),
                                      ),
                                    ),
                                    AppPressable(
                                      onPressed: _swap,
                                      borderless: true,
                                      rippleColor: palette.text,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        margin: const EdgeInsets.only(
                                          right: Tokens.spaceSm,
                                        ),
                                        decoration: BoxDecoration(
                                          color: palette.background,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: palette.border,
                                          ),
                                        ),
                                        child: Icon(
                                          AppIcons.swapVertical,
                                          size: 16,
                                          color: palette.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          AppButton(
                            label: 'Find Routes',
                            enabled: _canSearch,
                            icon: AppIcons.magnify,
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                Routes.journeyResults,
                                arguments: JourneyResultsArgs(
                                  fromKey: _from!.id,
                                  toKey: _to!.id,
                                  fromName: _from!.name,
                                  toName: _to!.name,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // How it works
                    const Padding(
                      padding: EdgeInsets.only(
                        left: AppSpacing.screen,
                        right: AppSpacing.screen,
                        top: Tokens.spaceLg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SectionHeader(
                            text: 'HOW IT WORKS',
                            margin: EdgeInsets.only(bottom: Tokens.spaceSm),
                          ),
                          _HowItWorksRow(
                            icon: AppIcons.busMultiple,
                            title: 'All Bus Types',
                            subtitle:
                                'Speedo, Metro, Orange Line & Electric buses',
                            number: '01',
                          ),
                          _HowItWorksRow(
                            icon: AppIcons.routes,
                            title: 'Direct or One Transfer',
                            subtitle: "We'll find the best route for you",
                            number: '02',
                          ),
                          _HowItWorksRow(
                            icon: AppIcons.wifiOff,
                            title: 'Works Offline',
                            subtitle: 'No internet needed to find your route',
                            number: '03',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `StopField` — labelled stop picker row (Metro module 569).
class _StopField extends StatelessWidget {
  const _StopField({
    required this.label,
    required this.accent,
    required this.icon,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final IconData icon;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return AppPressable(
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Tokens.spaceSm),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.32)),
              ),
              child: Icon(icon, size: 17, color: accent),
            ),
            const SizedBox(width: Tokens.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: Tokens.fontXs,
                      fontWeight: FontWeight.w700,
                      color: palette.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Tokens.fontBase,
                      fontWeight: value != null
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: value != null
                          ? palette.text
                          : palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(AppIcons.chevronRight, size: 18, color: palette.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// `HowItWorksRow` (Metro module 569).
class _HowItWorksRow extends StatelessWidget {
  const _HowItWorksRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.number,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String number;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return Container(
      margin: const EdgeInsets.only(bottom: Tokens.spaceSm),
      padding: const EdgeInsets.all(Tokens.spaceMd),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(Tokens.shapeLg),
        border: Border.all(color: palette.border),
        boxShadow: palette.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: palette.heroGradient,
              borderRadius: BorderRadius.circular(Tokens.shapeMd),
              boxShadow: palette.softShadow,
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: Tokens.spaceSm),
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: Tokens.fontSm,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            number,
            style: TextStyle(
              fontSize: Tokens.fontSm,
              fontWeight: FontWeight.w800,
              color: palette.primary.withValues(alpha: 0.32),
            ),
          ),
        ],
      ),
    );
  }
}
