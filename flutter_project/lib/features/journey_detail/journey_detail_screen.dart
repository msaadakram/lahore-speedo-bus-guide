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

/// JourneyDetailScreen — step-by-step directions for a chosen journey.
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
    final journey = widget.args.journey;
    final lines = <String>[
      'Journey: ${journey.startClock} → ${journey.arrivalClock}',
    ];
    for (final leg in journey.legs) {
      lines.add(
        'Take ${leg.routeName} from ${leg.fromName} to ${leg.toName}'
        ' (${leg.departureClock} → ${leg.arrivalClock})',
      );
    }
    if (journey.transferWalk != null && journey.transferWalk!.walkMeters > 0) {
      lines.add(
        'Walk ${Departures.formatWalkDistance(journey.transferWalk!.walkMeters)} '
        'to ${journey.transferWalk!.toName}',
      );
    }
    lines.add(
      'Total: ~${Departures.formatMinutes(journey.estimatedMinutes)} · Rs ${journey.totalFare}',
    );
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final journey = widget.args.journey;
    final title = journey.transfers == 0
        ? 'Direct'
        : '${journey.transfers} Transfer${journey.transfers == 1 ? '' : 's'}';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppCanvas(
        child: Column(
          children: [
            AppPageHeader(
              title: title,
              subtitle:
                  '${journey.startClock} → ${journey.arrivalClock} · Scheduled',
              onBack: () => Navigator.of(context).pop(),
              bottomRadius: 36,
              trailing: AppGlassButton(
                icon: AppIcons.share,
                tooltip: 'Share journey',
                size: 38,
                iconSize: 20,
                onPressed: () => Share.share(_shareText),
              ),
              bottom: Wrap(
                spacing: Tokens.spaceSm,
                runSpacing: Tokens.spaceSm,
                children: [
                  _HeaderChip(
                    icon: AppIcons.directionsWalk,
                    label:
                        '${journey.totalStops} stops · ${journey.transfers} change${journey.transfers == 1 ? '' : 's'}',
                  ),
                  _HeaderChip(
                    icon: AppIcons.send,
                    label: 'Rs ${journey.totalFare}',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  Tokens.spaceMd,
                  AppSpacing.screen,
                  Tokens.spaceXl,
                ),
                children: [
                  AppCard(
                    radius: Tokens.shapeXl,
                    elevated: true,
                    padding: const EdgeInsets.all(Tokens.spaceSm),
                    child: Row(
                      children: [
                        StatBox(
                          label: 'DURATION',
                          value:
                              '~${Departures.formatMinutes(journey.estimatedMinutes)}',
                          color: palette.primary,
                          icon: AppIcons.clock,
                        ),
                        const SizedBox(width: Tokens.spaceSm),
                        StatBox(
                          label: 'CHANGES',
                          value: '${journey.transfers}',
                          color: palette.primaryBright,
                          icon: AppIcons.routes,
                        ),
                        const SizedBox(width: Tokens.spaceSm),
                        StatBox(
                          label: 'FARE',
                          value: 'Rs ${journey.totalFare}',
                          color: palette.primary,
                          icon: AppIcons.send,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Tokens.spaceLg),
                  const SectionHeader(text: 'Step-by-step directions'),
                  const SizedBox(height: Tokens.spaceSm),
                  for (var i = 0; i < journey.legs.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Tokens.spaceSm),
                      child: _LegCard(
                        leg: journey.legs[i],
                        index: i + 1,
                        expanded: _expanded.contains(i),
                        onToggle: () => setState(() {
                          if (!_expanded.add(i)) {
                            _expanded.remove(i);
                          }
                        }),
                      ),
                    ),
                  if (journey.transferWalk != null &&
                      journey.transferWalk!.walkMeters > 0)
                    AppCard(
                      radius: Tokens.shapeXl,
                      elevated: true,
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: palette.primary.withValues(alpha: .12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              AppIcons.directionsWalk,
                              size: 19,
                              color: palette.primary,
                            ),
                          ),
                          const SizedBox(width: Tokens.spaceSm),
                          Expanded(
                            child: Text(
                              'Transfer walk to ${journey.transferWalk!.toName} · '
                              '${Departures.formatWalkDistance(journey.transferWalk!.walkMeters)}',
                              style: TextStyle(
                                fontSize: Tokens.fontMd,
                                fontWeight: FontWeight.w600,
                                color: palette.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: Tokens.spaceLg),
                  AppCard(
                    radius: Tokens.shapeXl,
                    elevated: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(text: 'Travel Tips'),
                        const SizedBox(height: Tokens.spaceSm),
                        _tip(
                          'Times are estimates — allow extra time for connections',
                        ),
                        _tip(
                          'Fares shown are per leg — confirm with the conductor',
                        ),
                        _tip('Tap a leg for its full stop sequence'),
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

  Widget _tip(String text) {
    final palette = AppPaletteScope.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.check, size: 14, color: palette.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: Tokens.fontSm,
                height: 1.4,
                color: palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(Tokens.shapePill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: Tokens.fontSm,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
      radius: Tokens.shapeXl,
      elevated: true,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppPressable(
            onPressed: onToggle,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(Tokens.shapeXl),
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: color, width: 5)),
              ),
              padding: const EdgeInsets.all(Tokens.spaceMd),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(Tokens.shapeMd),
                      border: Border.all(color: color.withValues(alpha: .28)),
                    ),
                    child: BusIcon(
                      category: route?.category ?? 'bus',
                      size: 26,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: Tokens.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leg.routeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: Tokens.fontBase,
                            fontWeight: FontWeight.w800,
                            color: palette.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${leg.departureClock} → ${leg.arrivalClock} · ${leg.stopsTravelled} stops',
                          style: TextStyle(
                            fontSize: Tokens.fontSm,
                            fontWeight: FontWeight.w600,
                            color: palette.textSecondary,
                          ),
                        ),
                        Text(
                          '${leg.fromName} → ${leg.toName}',
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
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                Tokens.spaceMd,
                0,
                Tokens.spaceMd,
                Tokens.spaceMd,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < leg.stopNames.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: i == 0 || i == leg.stopNames.length - 1
                                ? 10
                                : 7,
                            height: i == 0 || i == leg.stopNames.length - 1
                                ? 10
                                : 7,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: Tokens.spaceSm),
                          Expanded(
                            child: Text(
                              leg.stopNames[i],
                              style: TextStyle(
                                fontSize: Tokens.fontSm,
                                fontWeight:
                                    i == 0 || i == leg.stopNames.length - 1
                                    ? FontWeight.w800
                                    : FontWeight.w500,
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
          ),
        ],
      ),
    );
  }
}
