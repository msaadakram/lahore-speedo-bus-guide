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

/// RouteDetailScreen (Metro module 1020).
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
    final insets = MediaQuery.paddingOf(context);
    final data = ref.watch(routesDataProvider);
    final route = data.valueOrNull?.routeById(widget.args.routeId);

    if (route == null) {
      return Scaffold(
        body: Column(
          children: [
            AppPageHeader(
              title: 'Route',
              onBack: () => Navigator.of(context).pop(),
            ),
            const Expanded(
              child: EmptyState(icon: AppIcons.bus, message: 'Route not found'),
            ),
          ],
        ),
      );
    }

    final lineColor = parseRouteColor(route.color);
    final order = List<int>.generate(route.stops.length, (i) => i);
    final stops = _reversed ? order.reversed.toList() : order;
    final departures = Departures.getNextDepartures(
      route.frequency,
      route.operatingHours,
      limit: 5,
    );

    return Scaffold(
      body: ColoredBox(
        color: palette.background,
        child: Column(
          children: [
            // ---------------------------------------------------- header
            Container(
              decoration: BoxDecoration(gradient: palette.heroGradient),
              padding: EdgeInsets.only(
                left: Tokens.spaceMd,
                right: Tokens.spaceMd,
                top: insets.top + Tokens.spaceSm,
                bottom: Tokens.spaceMd,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              route.stationAddress,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: Tokens.fontLg,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              route.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: Tokens.fontSm,
                                color: Color(0xCCFFFFFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppPressable(
                        onPressed: () => Share.share(
                          '${route.name} · ${route.frequency ?? ''} | ${route.operatingHours ?? ''}',
                        ),
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
                    children: [
                      Expanded(
                        child: Text(
'Towards ${route.stops[_reversed ? 0 : route.stops.length - 1]}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: Tokens.fontSm,
                            color: Color(0xE6FFFFFF),
                          ),
                        ),
                      ),
                      AppPressable(
                        onPressed: () => Navigator.of(context).pushNamed(
                          Routes.map,
                          arguments: MapArgs(routeId: route.id),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Tokens.spaceSm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x33FFFFFF),
                            borderRadius: BorderRadius.circular(
                              Tokens.radiusFull,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(AppIcons.map, size: 16, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'View on Map',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: Tokens.fontSm,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ---------------------------------------------------- body
            Expanded(
              child: ListView(
                key: const Key('route-detail-list'),
                padding: const EdgeInsets.only(bottom: Tokens.spaceXl),
                children: [
                  // Stats
                  Padding(
                    padding: const EdgeInsets.all(Tokens.spaceMd),
                    child: Row(
                      children: [
                        StatBox(
                          label: 'FARE',
                          value: 'Rs. ${route.fare}',
                          color: palette.primary,
                        ),
                        const SizedBox(width: Tokens.spaceSm),
                        StatBox(
                          label: 'FREQUENCY',
                          value: route.frequency ?? '—',
                          color: palette.primary,
                        ),
                        const SizedBox(width: Tokens.spaceSm),
                        StatBox(
                          label: 'HOURS',
                          value: route.operatingHours ?? '—',
                          color: palette.primary,
                        ),
                        const SizedBox(width: Tokens.spaceSm),
                        StatBox(
                          label: 'TOTAL STOPS',
                          value: '${route.stops.length}',
                          color: palette.primary,
                        ),
                      ],
                    ),
                  ),

                  // Next departures
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen,
                    ),
                    child: SectionHeader(
                      text: 'NEXT DEPARTURES',
                      margin: EdgeInsets.only(bottom: Tokens.spaceSm),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen,
                    ),
                    child: Wrap(
                      spacing: Tokens.spaceSm,
                      runSpacing: Tokens.spaceSm,
                      children: departures.isEmpty
                          ? [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Tokens.spaceMd,
                                  vertical: Tokens.spaceSm,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.card,
                                  borderRadius: BorderRadius.circular(
                                    Tokens.radiusFull,
                                  ),
                                  border: Border.all(color: palette.border),
                                ),
                                child: Text(
                                  'No more buses today',
                                  style: TextStyle(
                                    fontSize: Tokens.fontSm,
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ),
                            ]
                          : departures
                                .map(
                                  (d) => _DepartureChip(
                                    route: route,
                                    value: d.display,
                                    reversed: _reversed,
                                  ),
                                )
                                .toList(),
                    ),
                  ),

                  const SizedBox(height: Tokens.spaceLg),

                  // "View on Map" action (original: a coloured button below
                  // the stat boxes).
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen,
                    ),
                    child: AppPressable(
                      onPressed: () => Navigator.of(context).pushNamed(
                        Routes.map,
                        arguments: MapArgs(
                          routeId: route.id,
                          color: route.color,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Tokens.spaceMd,
                          vertical: Tokens.spaceMd,
                        ),
                        decoration: BoxDecoration(
                          color: palette.primary,
                          borderRadius: BorderRadius.circular(Tokens.radiusLg),
                        ),
                        child: const Row(
                          children: [
                            Icon(AppIcons.map, size: 18, color: Colors.white),
                            SizedBox(width: Tokens.spaceSm),
                            Expanded(
                              child: Text(
                                'View on Map',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: Tokens.fontBase,
                                ),
                              ),
                            ),
                            Icon(
                              AppIcons.arrowRight,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Stops header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stops',
                          style: TextStyle(
                            fontSize: Tokens.fontXl,
                            fontWeight: FontWeight.w800,
                            color: palette.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Stops along this route',
                          style: TextStyle(
                            fontSize: Tokens.fontSm,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen,
                    ),
                    child: Row(
                      children: [
                        const SizedBox.shrink(),
                        AppPressable(
                          onPressed: () =>
                              setState(() => _reversed = !_reversed),
                          child: Container(
                            padding: const EdgeInsets.all(Tokens.spaceSm),
                            decoration: BoxDecoration(
                              color: palette.card,
                              borderRadius: BorderRadius.circular(
                                Tokens.radiusFull,
                              ),
                              border: Border.all(color: palette.border),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  AppIcons.swapVertical,
                                  size: 16,
                                  color: palette.text,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'DIRECTION',
                                  style: TextStyle(
                                    fontSize: Tokens.fontXs,
                                    fontWeight: FontWeight.w800,
                                    color: palette.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stop list
                  for (var i = 0; i < stops.length; i++)
                    _StopTile(
                      route: route,
                      index: stops[i],
                      isFirst: i == 0,
                      isLast: i == stops.length - 1,
                      lineColor: lineColor,
                    ),

                  const SizedBox(height: Tokens.spaceLg),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen,
                    ),
                    child: Text(
                      'Bus times may vary due to traffic conditions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: Tokens.fontSm,
                        fontStyle: FontStyle.italic,
                        color: palette.textSecondary,
                      ),
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Tokens.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: Tokens.fontBase,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            'from $stop',
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
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: 2,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isFirst ? Colors.transparent : lineColor,
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isFirst || isLast ? lineColor : palette.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: lineColor, width: 2),
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
              const SizedBox(width: Tokens.spaceMd),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Tokens.spaceMd),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stopName,
                              style: TextStyle(
                                fontSize: Tokens.fontMd,
                                fontWeight: isFirst || isLast
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: palette.text,
                              ),
                            ),
                          ],
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
      ),
    );
  }
}
