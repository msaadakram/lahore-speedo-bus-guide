import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../app/theme/app_palette.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_tokens.dart';
import '../../data/repositories/departures.dart';
import '../../data/repositories/journey_repository.dart';
import '../../data/repositories/routes_provider.dart';
import '../../data/repositories/routes_repository.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/route_widgets.dart';

/// JourneyResultsScreen (Metro module 1075).
class JourneyResultsScreen extends ConsumerStatefulWidget {
  const JourneyResultsScreen({required this.args, super.key});

  final JourneyResultsArgs args;

  @override
  ConsumerState<JourneyResultsScreen> createState() =>
      _JourneyResultsScreenState();
}

class _JourneyResultsScreenState extends ConsumerState<JourneyResultsScreen> {
  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final insets = MediaQuery.paddingOf(context);
    final data = ref.watch(routesDataProvider);
    final journeys = data.valueOrNull == null
        ? const <Journey>[]
        : JourneyRepository.findJourneys(
            widget.args.fromKey,
            widget.args.toKey,
          );

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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.args.fromName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: Tokens.fontLg,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              widget.args.toName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: Tokens.fontSm,
                                color: Color(0xE6FFFFFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Tokens.spaceSm),
                  Text(
                    '${journeys.length} ${journeys.length == 1 ? 'route' : 'routes'} found',
                    style: const TextStyle(
                      fontSize: Tokens.fontSm,
                      fontWeight: FontWeight.w600,
                      color: Color(0xE6FFFFFF),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: journeys.isEmpty
                  ? const EmptyState(
                      icon: AppIcons.bus,
                      message: 'No bus route found between these stops, even with a walking transfer.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        Tokens.spaceMd,
                        AppSpacing.screen,
                        Tokens.spaceXl,
                      ),
                      itemCount: journeys.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: Tokens.spaceSm),
                        child: _JourneyCard(
                          journey: journeys[i],
                          onTap: () => Navigator.of(context).pushNamed(
                            Routes.journeyDetail,
                            arguments: JourneyDetailArgs(journey: journeys[i]),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.journey, required this.onTap});

  final Journey journey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final route = RoutesRepository.instance.routeById(
      journey.legs.first.routeId,
    );
    final first = journey.legs.first;
    final wait = first.waitMinutes;

    return AppPressable(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(Tokens.spaceMd),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(Tokens.radiusLg),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Tokens.spaceSm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Tokens.radiusFull),
                  ),
                  child: Text(
                    journey.transfers == 0
                        ? 'Direct'
                        : '${journey.transfers} transfer',
                    style: TextStyle(
                      fontSize: Tokens.fontSm,
                      fontWeight: FontWeight.w700,
                      color: palette.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '~${Departures.formatMinutes(journey.estimatedMinutes)}',
                  style: TextStyle(
                    fontSize: Tokens.fontMd,
                    fontWeight: FontWeight.w800,
                    color: palette.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Tokens.spaceSm),
            Row(
              children: [
                if (route != null)
                  BusIcon(
                    category: route.category,
                    size: 26,
                    color: parseRouteColor(route.color),
                  ),
                const SizedBox(width: Tokens.spaceSm),
                Expanded(
                  child: Text(
                    'Leave in $wait min · ${first.fromName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Tokens.fontMd,
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            for (final leg in journey.legs) ...[
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
            Text(
              journey.legs.last.toName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Tokens.fontSm,
                fontWeight: FontWeight.w600,
                color: palette.text,
              ),
            ),
            if (journey.transferWalk != null &&
                journey.transferWalk!.walkMeters > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Transfer walk to ${journey.transferWalk!.toName} · '
                '${Departures.formatWalkDistance(journey.transferWalk!.walkMeters)}',
                style: TextStyle(
                  fontSize: Tokens.fontSm,
                  color: palette.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: Tokens.spaceSm),
            Row(
              children: [
                Text(
                  'Rs ${journey.totalFare}',
                  style: TextStyle(
                    fontSize: Tokens.fontSm,
                    fontWeight: FontWeight.w700,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(width: Tokens.spaceMd),
                Text(
                  '${journey.totalStops} stops',
                  style: TextStyle(
                    fontSize: Tokens.fontSm,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
