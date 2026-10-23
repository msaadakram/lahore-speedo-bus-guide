import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/router.dart';
import '../../app/theme/app_palette.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_tokens.dart';
import '../../data/repositories/departures.dart';
import '../../data/repositories/journey_repository.dart';
import '../../data/repositories/routes_repository.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/route_widgets.dart';

/// JourneyDetailScreen (Metro module 1076).
class JourneyDetailScreen extends ConsumerStatefulWidget {
  const JourneyDetailScreen({required this.args, super.key});

  final JourneyDetailArgs args;

  @override
  ConsumerState<JourneyDetailScreen> createState() =>
      _JourneyDetailScreenState();
}

class _JourneyDetailScreenState extends ConsumerState<JourneyDetailScreen> {
  final Set<int> _expanded = <int>{0};

  String get _shareText {
    final j = widget.args.journey;
    final lines = <String>['Journey: ${j.startClock} → ${j.arrivalClock}'];
    for (final leg in j.legs) {
      lines.add(
        'Take ${leg.routeName} from ${leg.fromName} to ${leg.toName}'
        ' (${leg.departureClock} → ${leg.arrivalClock})',
      );
    }
    if (j.transferWalk != null && j.transferWalk!.walkMeters > 0) {
      lines.add(
        'Walk ${Departures.formatWalkDistance(j.transferWalk!.walkMeters)} '
        'to ${j.transferWalk!.toName}',
      );
    }
    lines.add(
      'Total: ~${Departures.formatMinutes(j.estimatedMinutes)} · Rs ${j.totalFare}',
    );
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final insets = MediaQuery.paddingOf(context);
    final journey = widget.args.journey;

    return Scaffold(
      body: ColoredBox(
        color: palette.background,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: palette.heroGradient,
                boxShadow: palette.softShadow,
              ),
              padding: EdgeInsets.only(
                left: Tokens.spaceMd,
                right: Tokens.spaceMd,
                top: insets.top + Tokens.spaceSm,
                bottom: Tokens.spaceSm,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      AppPressable(
                        onPressed: () => Navigator.of(context).pop(),
                        borderless: true,
                        rippleColor: Colors.white,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            AppIcons.arrowLeft,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          journey.transfers == 0 ? 'Direct' : '1 Transfer',
                          style: const TextStyle(
                            fontSize: Tokens.fontXl,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      AppPressable(
                        onPressed: () => Share.share(_shareText),
                        borderless: true,
                        rippleColor: Colors.white,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            AppIcons.share,
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Tokens.spaceSm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${journey.startClock} → ${journey.arrivalClock}',
                        style: const TextStyle(
                          fontSize: Tokens.fontMd,
                          fontWeight: FontWeight.w700,
                          color: Color(0xE6FFFFFF),
                        ),
                      ),
                      const Text(
                        'Scheduled',
                        style: TextStyle(
                          fontSize: Tokens.fontXs,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: Tokens.spaceXl),
                children: [
                  // stats
                  Padding(
                    padding: const EdgeInsets.all(Tokens.spaceMd),
                    child: Row(
                      children: [
                        StatBox(
                          label: 'DURATION',
                          value:
                              '~${Departures.formatMinutes(journey.estimatedMinutes)}',
                          color: palette.primary,
                        ),
                        const SizedBox(width: Tokens.spaceSm),
                        StatBox(
                          label: 'CHANGES',
                          value: '${journey.transfers}',
                          color: palette.primary,
                        ),
                        const SizedBox(width: Tokens.spaceSm),
                        StatBox(
                          label: 'FARE',
                          value: 'Rs ${journey.totalFare}',
                          color: palette.primary,
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen,
                    ),
                    child: SectionHeader(
                      text: 'Step-by-step directions',
                      margin: EdgeInsets.only(bottom: Tokens.spaceSm),
                    ),
                  ),

                  // legs
                  for (var i = 0; i < journey.legs.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screen,
                        vertical: Tokens.spaceXs,
                      ),
                      child: _LegCard(
                        leg: journey.legs[i],
                        index: i + 1,
                        expanded: _expanded.contains(i),
                        onToggle: () => setState(() {
                          if (_expanded.contains(i)) {
                            _expanded.remove(i);
                          } else {
                            _expanded.add(i);
                          }
                        }),
                      ),
                    ),

                  if (journey.transferWalk != null &&
                      journey.transferWalk!.walkMeters > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        Tokens.spaceSm,
                        AppSpacing.screen,
                        Tokens.spaceXs,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(Tokens.spaceMd),
                        decoration: BoxDecoration(
                          color: palette.card,
                          borderRadius: BorderRadius.circular(Tokens.radiusLg),
                          border: Border.all(color: palette.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              AppIcons.directionsWalk,
                              size: 20,
                              color: palette.primary,
                            ),
                            const SizedBox(width: Tokens.spaceSm),
                            Expanded(
                              child: Text(
                                'Transfer walk to ${journey.transferWalk!.toName} · '
                                '${Departures.formatWalkDistance(journey.transferWalk!.walkMeters)}',
                                style: TextStyle(
                                  fontSize: Tokens.fontMd,
                                  color: palette.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // travel tips
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      Tokens.spaceMd,
                      AppSpacing.screen,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          text: 'Travel Tips',
                          margin: EdgeInsets.only(bottom: Tokens.spaceSm),
                        ),
                        _tip(
                          palette,
                          'Times are estimates — allow extra time for connections',
                        ),
                        _tip(
                          palette,
                          'Fares shown are per leg — confirm with the conductor',
                        ),
                        _tip(palette, 'Tap for full route details'),
                      ],
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

  Widget _tip(AppPalette palette, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• ', style: TextStyle(color: palette.primary)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: Tokens.fontSm,
              color: palette.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _LegCard extends StatelessWidget {
  const _LegCard({
    required this.leg,
    required this.index,
    required this.expanded,
    required this.onToggle,
  });

  final Leg leg;
  final int index;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final route = RoutesRepository.instance.routeById(leg.routeId);
    final color = parseRouteColor(leg.color);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppPressable(
            onPressed: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(Tokens.spaceMd),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(Tokens.radiusMd),
                    ),
                    child: BusIcon(
                      category: route?.category ?? 'bus',
                      size: 24,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: Tokens.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${leg.departureClock} → ${leg.arrivalClock}',
                          style: TextStyle(
                            fontSize: Tokens.fontSm,
                            fontWeight: FontWeight.w800,
                            color: palette.text,
                          ),
                        ),
                        Text(
                          'Take ${leg.routeName} · ${leg.stopsTravelled} stops',
                          style: TextStyle(
                            fontSize: Tokens.fontMd,
                            fontWeight: FontWeight.w600,
                            color: palette.text,
                          ),
                        ),
                        Text(
                          leg.fromName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: Tokens.fontSm,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded ? AppIcons.chevronDown : AppIcons.chevronRight,
                    color: palette.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Tokens.spaceMd,
                0,
                Tokens.spaceMd,
                Tokens.spaceMd,
              ),
              child: Column(
                children: [
                  for (final name in leg.stopNames)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: Tokens.spaceSm),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: Tokens.fontSm,
                                color: palette.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
