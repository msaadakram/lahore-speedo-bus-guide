import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/router.dart';
import '../../app/theme/app_palette.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_tokens.dart';
import '../../data/models/route.dart';
import '../../data/repositories/departures.dart';
import '../../data/repositories/routes_provider.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/route_widgets.dart';

/// RouteDetailScreen — one line's fare, running times, departures and stops.
class RouteDetailScreen extends ConsumerStatefulWidget {
  const RouteDetailScreen({required this.args, super.key});

  final RouteDetailArgs args;

  @override
  ConsumerState<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends ConsumerState<RouteDetailScreen> {
  bool _reversed = false;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final data = ref.watch(routesDataProvider);
    final route = data.valueOrNull?.routeById(widget.args.routeId);

    if (data.isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: AppCanvas(
          child: Column(
            children: [
              AppPageHeader(
                title: 'Route',
                subtitle: 'Loading timetable…',
                onBack: () => Navigator.of(context).pop(),
              ),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
        ),
      );
    }

    if (data.hasError) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: AppCanvas(
          child: Column(
            children: [
              AppPageHeader(
                title: 'Route',
                subtitle: 'Data unavailable',
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: EmptyState(
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
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (route == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: AppCanvas(
          child: Column(
            children: [
              AppPageHeader(
                title: 'Route',
                onBack: () => Navigator.of(context).pop(),
              ),
              const Expanded(
                child: EmptyState(
                  icon: AppIcons.bus,
                  title: 'Route not found',
                  message: 'This route is not in the bundled dataset.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final lineColor = parseRouteColor(route.color);
    final order = List<int>.generate(route.stops.length, (i) => i);
    final stopIndexes = _reversed ? order.reversed.toList() : order;
    final departures = Departures.getNextDepartures(
      route.frequency,
      route.operatingHours,
      limit: 5,
    );
    final destination = route.stops[_reversed ? 0 : route.stops.length - 1];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppCanvas(
        child: Column(
          children: [
            AppPageHeader(
              title: route.name,
              subtitle: route.stationAddress,
              onBack: () => Navigator.of(context).pop(),
              bottomRadius: 36,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppGlassButton(
                    icon: AppIcons.share,
                    tooltip: 'Share route',
                    size: 38,
                    iconSize: 20,
                    onPressed: () => Share.share(_shareText(route)),
                  ),
                  const SizedBox(width: Tokens.spaceSm),
                  AppGlassButton(
                    icon: AppIcons.map,
                    tooltip: 'View on map',
                    size: 38,
                    iconSize: 20,
                    onPressed: () => Navigator.of(context).pushNamed(
                      Routes.map,
                      arguments: MapArgs(
                        routeId: route.id,
                        color: route.color,
                        title: route.name,
                      ),
                    ),
                  ),
                ],
              ),
              bottom: Wrap(
                spacing: Tokens.spaceSm,
                runSpacing: Tokens.spaceSm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _HeaderChip(
                    icon: AppIcons.flag,
                    label: 'Towards $destination',
                  ),
                  _HeaderChip(
                    icon: AppIcons.stop,
                    label: '${route.stops.length} stops',
                  ),
                  if (route.operatingHours != null)
                    _HeaderChip(
                      icon: AppIcons.clock,
                      label: route.operatingHours!,
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                key: const Key('route-detail-list'),
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
                    child: Column(
                      children: [
                        Row(
                          children: [
                            StatBox(
                              label: 'FARE',
                              value: 'Rs. ${route.fare}',
                              color: palette.primary,
                              icon: AppIcons.send,
                            ),
                            const SizedBox(width: Tokens.spaceSm),
                            StatBox(
                              label: 'FREQUENCY',
                              value: route.frequency ?? '—',
                              color: palette.primary,
                              icon: AppIcons.loop,
                            ),
                          ],
                        ),
                        const SizedBox(height: Tokens.spaceSm),
                        Row(
                          children: [
                            StatBox(
                              label: 'HOURS',
                              value: route.operatingHours ?? '—',
                              color: palette.primary,
                              icon: AppIcons.clock,
                            ),
                            const SizedBox(width: Tokens.spaceSm),
                            StatBox(
                              label: 'TOTAL STOPS',
                              value: '${route.stops.length}',
                              color: palette.primary,
                              icon: AppIcons.stop,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Tokens.spaceMd),
                  const SectionHeader(text: 'NEXT DEPARTURES'),
                  const SizedBox(height: Tokens.spaceSm),
                  AppCard(
                    radius: Tokens.shapeXl,
                    elevated: true,
                    child: departures.isEmpty
                        ? Text(
                            'No more buses today',
                            style: TextStyle(
                              fontSize: Tokens.fontMd,
                              fontWeight: FontWeight.w600,
                              color: palette.textSecondary,
                            ),
                          )
                        : Wrap(
                            spacing: Tokens.spaceSm,
                            runSpacing: Tokens.spaceSm,
                            children: [
                              for (final departure in departures)
                                _DepartureChip(
                                  route: route,
                                  value: departure.display,
                                  reversed: _reversed,
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(height: Tokens.spaceLg),
                  AppButton(
                    label: 'View on Map',
                    icon: AppIcons.map,
                    onPressed: () => Navigator.of(context).pushNamed(
                      Routes.map,
                      arguments: MapArgs(
                        routeId: route.id,
                        color: route.color,
                        title: route.name,
                      ),
                    ),
                  ),
                  const SizedBox(height: Tokens.spaceLg),
                  AppCard(
                    radius: Tokens.shapeXl,
                    elevated: true,
                    padding: const EdgeInsets.all(Tokens.spaceMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Stops',
                                style: TextStyle(
                                  fontSize: Tokens.fontLg,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            AppPressable(
                              onPressed: () =>
                                  setState(() => _reversed = !_reversed),
                              borderRadius: BorderRadius.circular(
                                Tokens.shapePill,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Tokens.spaceSm,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.surfaceTint,
                                  borderRadius: BorderRadius.circular(
                                    Tokens.shapePill,
                                  ),
                                  border: Border.all(color: palette.border),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      AppIcons.swapVertical,
                                      size: 14,
                                      color: palette.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'DIRECTION',
                                      style: TextStyle(
                                        fontSize: Tokens.fontXs,
                                        fontWeight: FontWeight.w800,
                                        color: palette.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Tokens.spaceSm),
                        for (var i = 0; i < stopIndexes.length; i++)
                          _StopTile(
                            route: route,
                            index: stopIndexes[i],
                            isFirst: i == 0,
                            isLast: i == stopIndexes.length - 1,
                            lineColor: lineColor,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Tokens.spaceMd),
                  Text(
                    'Bus times may vary due to traffic conditions',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: Tokens.fontSm,
                      fontStyle: FontStyle.italic,
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

  String _shareText(BusRoute route) => [
    route.name,
    if (route.frequency != null && route.frequency!.isNotEmpty)
      route.frequency!,
    if (route.operatingHours != null) route.operatingHours!,
    'Fare: Rs. ${route.fare}',
    'Stops: ${route.stops.join(' → ')}',
  ].join('\n');
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

class _DepartureChip extends StatelessWidget {
  const _DepartureChip({
    required this.route,
    required this.value,
    required this.reversed,
  });

  final BusRoute route;
  final String value;
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final color = parseRouteColor(route.color);
    final stop = reversed ? route.stops.last : route.stops.first;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.spaceMd,
        vertical: Tokens.spaceSm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(Tokens.shapePill),
        border: Border.all(color: color.withValues(alpha: .30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: Tokens.fontBase,
              fontWeight: FontWeight.w900,
              color: palette.text,
            ),
          ),
          Text(
            'from $stop',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Tokens.fontXs,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.route,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.lineColor,
  });

  final BusRoute route;
  final int index;
  final bool isFirst;
  final bool isLast;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final stopName = route.stops[index];
    return AppPressable(
      onPressed: () => Navigator.of(context).pushNamed(
        Routes.stopDetail,
        arguments: StopDetailArgs(stopName: stopName),
      ),
      borderRadius: BorderRadius.circular(Tokens.shapeLg),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isFirst ? Colors.transparent : lineColor,
                    ),
                  ),
                  Container(
                    width: isFirst || isLast ? 12 : 10,
                    height: isFirst || isLast ? 12 : 10,
                    decoration: BoxDecoration(
                      color: isFirst || isLast ? lineColor : palette.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: lineColor, width: 2.5),
                      boxShadow: isFirst || isLast
                          ? [
                              BoxShadow(
                                color: lineColor.withValues(alpha: .28),
                                blurRadius: 8,
                                spreadRadius: -1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isLast ? Colors.transparent : lineColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Tokens.spaceSm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Tokens.spaceSm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        stopName,
                        style: TextStyle(
                          fontSize: Tokens.fontMd,
                          fontWeight: isFirst || isLast
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: palette.text,
                        ),
                      ),
                    ),
                    Icon(
                      AppIcons.chevronRight,
                      size: 16,
                      color: palette.textSecondary,
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
