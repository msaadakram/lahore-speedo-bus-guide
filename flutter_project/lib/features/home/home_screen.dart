import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../app/theme/app_palette.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_tokens.dart';
import '../../data/models/bus_stop.dart';
import '../../data/repositories/routes_repository.dart';
import '../../features/stop_picker/stop_picker_screen.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/route_widgets.dart';

/// RouteFinderScreen — the upgraded "Home" tab.
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
    final routes = RoutesRepository.instance.routes;
    final stops = RoutesRepository.instance.stops;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppCanvas(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Lahore 🇵🇰',
              subtitle: 'Every route, one tap away!',
              bottomRadius: 36,
              trailing: AppGlassButton(
                icon: AppIcons.magnify,
                tooltip: 'Search routes',
                onPressed: () => Navigator.of(context).pushNamed(Routes.search),
              ),
              bottom: const Wrap(
                spacing: Tokens.spaceSm,
                runSpacing: Tokens.spaceSm,
                children: [
                  TagChip(label: 'Speedo', asset: 'assets/images/speedo.jpg'),
                  TagChip(label: 'Metro', asset: 'assets/images/metro.jpg'),
                  TagChip(
                    label: 'Electric',
                    asset: 'assets/images/electric.jpg',
                  ),
                  TagChip(
                    label: 'Orange Line',
                    asset: 'assets/images/orangeline.jpg',
                  ),
                  TagChip(label: 'Offline', icon: AppIcons.wifiOff),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: Tokens.spaceXl),
                children: [
                  _JourneyPlannerCard(
                    from: _from,
                    to: _to,
                    canSearch: _canSearch,
                    onPick: _openPicker,
                    onSwap: _swap,
                    onClearFrom: () => setState(() => _from = null),
                    onClearTo: () => setState(() => _to = null),
                    onSearch: () {
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      Tokens.spaceLg,
                      AppSpacing.screen,
                      Tokens.spaceSm,
                    ),
                    child: Row(
                      children: [
                        _NetworkStat(
                          value: '${routes.length}',
                          label: 'Routes',
                        ),
                        const SizedBox(width: Tokens.spaceSm),
                        _NetworkStat(value: '${stops.length}', label: 'Stops'),
                        const SizedBox(width: Tokens.spaceSm),
                        const _NetworkStat(
                          value: 'Offline',
                          label: 'Always ready',
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      Tokens.spaceLg,
                      AppSpacing.screen,
                      Tokens.spaceSm,
                    ),
                    child: SectionHeader(text: 'HOW IT WORKS'),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen,
                    ),
                    child: _HowItWorksRow(
                      icon: AppIcons.busMultiple,
                      title: 'All Bus Types',
                      subtitle: 'Speedo, Metro, Orange Line & Electric buses',
                      number: '01',
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen,
                    ),
                    child: _HowItWorksRow(
                      icon: AppIcons.routes,
                      title: 'Direct or One Transfer',
                      subtitle: "We'll find the best route for you",
                      number: '02',
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen,
                    ),
                    child: _HowItWorksRow(
                      icon: AppIcons.wifiOff,
                      title: 'Works Offline',
                      subtitle: 'No internet needed to find your route',
                      number: '03',
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

class _JourneyPlannerCard extends StatelessWidget {
  const _JourneyPlannerCard({
    required this.from,
    required this.to,
    required this.canSearch,
    required this.onPick,
    required this.onSwap,
    required this.onClearFrom,
    required this.onClearTo,
    required this.onSearch,
  });

  final BusStop? from;
  final BusStop? to;
  final bool canSearch;
  final ValueChanged<String> onPick;
  final VoidCallback onSwap;
  final VoidCallback onClearFrom;
  final VoidCallback onClearTo;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return AppCard(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        Tokens.spaceMd,
        AppSpacing.screen,
        0,
      ),
      padding: const EdgeInsets.all(Tokens.spaceMd),
      radius: Tokens.shapeXl,
      elevated: true,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: Icon(AppIcons.routes, size: 18, color: palette.primary),
              ),
              const SizedBox(width: Tokens.spaceSm),
              const Expanded(
                child: Text(
                  'Plan a journey',
                  style: TextStyle(
                    fontSize: Tokens.fontMd,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Tokens.spaceSm),
          _StopField(
            label: 'FROM',
            accent: const Color(0xFFF08C00),
            icon: AppIcons.mapMarker,
            value: from?.name,
            placeholder: 'From — pick a stop',
            onTap: () => onPick('from'),
            onClear: onClearFrom,
          ),
          Padding(
            padding: const EdgeInsets.only(left: Tokens.spaceMd + 18),
            child: SizedBox(
              height: 1,
              child: ColoredBox(color: palette.border),
            ),
          ),
          Center(child: _SwapButton(onPressed: onSwap)),
          _StopField(
            label: 'TO',
            accent: const Color(0xFF2E7D32),
            icon: AppIcons.flag,
            value: to?.name,
            placeholder: 'To — pick a stop',
            onTap: () => onPick('to'),
            onClear: onClearTo,
          ),
          const SizedBox(height: Tokens.spaceSm),
          AppButton(
            label: 'Find Routes',
            enabled: canSearch,
            icon: AppIcons.magnify,
            onPressed: onSearch,
          ),
        ],
      ),
    );
  }
}

/// Labelled stop picker row.
class _StopField extends StatelessWidget {
  const _StopField({
    required this.label,
    required this.accent,
    required this.icon,
    required this.value,
    required this.placeholder,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final Color accent;
  final IconData icon;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return AppPressable(
      onPressed: onTap,
      borderRadius: BorderRadius.circular(Tokens.shapeLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Tokens.spaceSm),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .14),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: .32)),
              ),
              child: Icon(icon, size: 18, color: accent),
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
                      fontWeight: FontWeight.w800,
                      color: palette.textSecondary,
                      letterSpacing: .7,
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
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: value != null
                          ? palette.text
                          : palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (value != null)
              _ClearIconButton(
                icon: AppIcons.close,
                onPressed: onClear,
                color: palette.textSecondary,
              )
            else
              Icon(
                AppIcons.chevronRight,
                size: 18,
                color: palette.textSecondary,
              ),
            const SizedBox(width: Tokens.spaceSm),
          ],
        ),
      ),
    );
  }
}

class _SwapButton extends StatelessWidget {
  const _SwapButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return AppPressable(
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.surfaceTint,
          shape: BoxShape.circle,
          border: Border.all(color: palette.border),
        ),
        child: Icon(AppIcons.swapVertical, size: 18, color: palette.primary),
      ),
    );
  }
}

/// Small circular icon action for non-hero surfaces.
class _ClearIconButton extends StatelessWidget {
  const _ClearIconButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onPressed: onPressed,
      semanticLabel: 'Clear selected stop',
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _NetworkStat extends StatelessWidget {
  const _NetworkStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Tokens.spaceSm),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(Tokens.shapeLg),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Tokens.fontLg,
                fontWeight: FontWeight.w900,
                color: palette.primary,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Tokens.fontXs,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `HowItWorksRow` — a numbered, elevated summary card.
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: palette.heroGradient,
              borderRadius: BorderRadius.circular(Tokens.shapeMd),
              boxShadow: palette.softShadow,
            ),
            child: Icon(icon, size: 22, color: Colors.white),
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
                    fontWeight: FontWeight.w800,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: Tokens.fontSm,
                    height: 1.35,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            number,
            style: TextStyle(
              fontSize: Tokens.fontLg,
              fontWeight: FontWeight.w900,
              color: palette.primary.withValues(alpha: .28),
            ),
          ),
        ],
      ),
    );
  }
}
