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

/// JourneyResultsScreen — ranked route options for a selected origin and
/// destination.
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
    final data = ref.watch(routesDataProvider);
    final failed = data.hasError;
    final loading = data.isLoading && !failed;
    final journeys = loading || failed
        ? const <Journey>[]
        : JourneyRepository.findJourneys(
            widget.args.fromKey,
            widget.args.toKey,
          );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppCanvas(
        child: Column(
          children: [
            AppPageHeader(
              title: widget.args.fromName,
              subtitle: 'To ${widget.args.toName}',
              onBack: () => Navigator.of(context).pop(),
              bottomRadius: 36,
              bottom: Text(
                failed
                    ? 'Route data unavailable'
                    : loading
                    ? 'Finding routes…'
                    : '${journeys.length} ${journeys.length == 1 ? 'route' : 'routes'} found',
                style: const TextStyle(
                  fontSize: Tokens.fontSm,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: failed
                  ? EmptyState(
                      icon: AppIcons.alertTriangle,
                      title: 'Route data unavailable',
                      message: 'The bundled route dataset could not be loaded on this device.',
                      action: AppButton(
                        label: 'Retry',
                        icon: AppIcons.reload,
                        expand: false,
                        onPressed: () {
                          ref.invalidate(routesDataProvider);
                        },
                      ),
                    )
                  : loading
                  ? const Center(child: CircularProgressIndicator())
                  : journeys.isEmpty
                  ? const EmptyState(
                      icon: AppIcons.bus,
                      title: 'No route found',
                      message: 'No bus route connects these stops, even with a short walking transfer.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        Tokens.spaceMd,
                        AppSpacing.screen,
                        Tokens.spaceXl,
                      ),
                      itemCount: journeys.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: Tokens.spaceSm),
                      itemBuilder: (context, index) {
                        final journey = journeys[index];
                        return _JourneyCard(
                          journey: journey,
                          onTap: () => Navigator.of(context).pushNamed(
                            Routes.journeyDetail,
                            arguments: JourneyDetailArgs(journey: journey),
                          ),
                        );
                      },
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
    final first = journey.legs.first;
    final transferLabel = journey.transfers == 0
        ? 'Direct'
        : '${journey.transfers} transfer';

    return AppCard(
      radius: Tokens.shapeXl,
      elevated: true,
      child: AppPressable(
        onPressed: onTap,
        borderRadius: BorderRadius.circular(Tokens.shapeXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Tokens.spaceSm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(Tokens.shapePill),
                  ),
                  child: Text(
                    transferLabel,
                    style: TextStyle(
                      fontSize: Tokens.fontSm,
                      fontWeight: FontWeight.w800,
                      color: palette.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '~${Departures.formatMinutes(journey.estimatedMinutes)}',
                      style: TextStyle(
                        fontSize: Tokens.fontLg,
                        fontWeight: FontWeight.w900,
                        color: palette.text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Tokens.spaceMd),
            for (var i = 0; i < journey.legs.length; i++) ...[
              _LegSummary(leg: journey.legs[i]),
              if (i != journey.legs.length - 1)
                Icon(
                  AppIcons.chevronDown,
                  size: 16,
                  color: palette.textSecondary,
                ),
            ],
            if (journey.transferWalk != null &&
                journey.transferWalk!.walkMeters > 0) ...[
              const SizedBox(height: Tokens.spaceSm),
              Row(
                children: [
                  Icon(
                    AppIcons.directionsWalk,
                    size: 16,
                    color: palette.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Walk ${Departures.formatWalkDistance(journey.transferWalk!.walkMeters)} to ${journey.transferWalk!.toName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Tokens.fontSm,
                        fontWeight: FontWeight.w600,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: Tokens.spaceMd),
            Wrap(
              spacing: Tokens.spaceSm,
              runSpacing: Tokens.spaceSm,
              children: [
                _JourneyChip(
                  icon: AppIcons.clock,
                  label: 'Leave in ${first.waitMinutes} min',
                ),
                _JourneyChip(
                  icon: AppIcons.stop,
                  label: '${journey.totalStops} stops',
                ),
                _JourneyChip(
                  icon: AppIcons.send,
                  label: 'Rs ${journey.totalFare}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegSummary extends StatelessWidget {
  const _LegSummary({required this.leg});

  final Leg leg;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final route = RoutesRepository.instance.routeById(leg.routeId);
    final color = parseRouteColor(leg.color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(Tokens.shapeSm),
              border: Border.all(color: color.withValues(alpha: .28)),
            ),
            child: BusIcon(
              category: route?.category ?? 'bus',
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: Tokens.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leg.routeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Tokens.fontMd,
                    fontWeight: FontWeight.w800,
                    color: palette.text,
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
          Text(
            '${leg.stopsTravelled} stops',
            style: TextStyle(
              fontSize: Tokens.fontXs,
              fontWeight: FontWeight.w800,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyChip extends StatelessWidget {
  const _JourneyChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surfaceTint,
        borderRadius: BorderRadius.circular(Tokens.shapePill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: palette.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: Tokens.fontXs,
              fontWeight: FontWeight.w700,
              color: palette.text,
            ),
          ),
        ],
      ),
    );
  }
}
