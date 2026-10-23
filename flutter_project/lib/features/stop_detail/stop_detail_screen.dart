import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../app/theme/app_palette.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_tokens.dart';
import '../../data/models/route.dart';
import '../../data/repositories/departures.dart';
import '../../data/repositories/routes_provider.dart';
import '../../data/repositories/stop_repository.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/route_widgets.dart';

/// StopDetailScreen (Metro module 1072).
class StopDetailScreen extends ConsumerStatefulWidget {
  const StopDetailScreen({required this.args, super.key});

  final StopDetailArgs args;

  @override
  ConsumerState<StopDetailScreen> createState() => _StopDetailScreenState();
}

class _StopDetailScreenState extends ConsumerState<StopDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final insets = MediaQuery.paddingOf(context);
    final data = ref.watch(routesDataProvider);
    final routes = data.valueOrNull?.routes ?? const <BusRoute>[];
    final key = widget.args.stopName.trim().toLowerCase();
    final stop = StopRepository.instance.byKey(key);
    final lines = stop == null
        ? <BusRoute>[]
        : StopRepository.instance
              .routesFor(stop.id)
              .map((r) => routes.where((x) => x.id == r.routeId).firstOrNull)
              .whereType<BusRoute>()
              .toList();

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
                          stop?.name ?? 'Stop',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: Tokens.fontXl,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      AppPressable(
                        onPressed: () => Navigator.of(context).pushNamed(
                          Routes.map,
                          arguments: MapArgs(stopId: key),
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
                  const SizedBox(height: Tokens.spaceSm),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Lines serving this stop',
                      style: TextStyle(
                        fontSize: Tokens.fontSm,
                        fontWeight: FontWeight.w600,
                        color: Color(0xE6FFFFFF),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: lines.isEmpty
                  ? const EmptyState(
                      icon: Icons.directions_bus_rounded,
                      message: 'No lines found for this stop.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        Tokens.spaceMd,
                        AppSpacing.screen,
                        Tokens.spaceXl,
                      ),
                      itemCount: lines.length,
                      itemBuilder: (context, i) => _LineCard(route: lines[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({required this.route});

  final BusRoute route;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final color = parseRouteColor(route.color);
    final departures = Departures.getNextDepartures(
      route.frequency,
      route.operatingHours,
      limit: 4,
    );

    return AppCard(
      margin: const EdgeInsets.only(bottom: Tokens.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppPressable(
            onPressed: () => Navigator.of(context).pushNamed(
              Routes.routeDetail,
              arguments: RouteDetailArgs(routeId: route.id, color: route.color),
            ),
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
                    category: route.category,
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
                        route.name,
                        style: TextStyle(
                          fontSize: Tokens.fontBase,
                          fontWeight: FontWeight.w700,
                          color: palette.text,
                        ),
                      ),
                      Text(
                        route.stationAddress,
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
                  AppIcons.chevronRight,
                  size: 18,
                  color: palette.textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: Tokens.spaceMd),
          Text(
            'Next departures',
            style: TextStyle(
              fontSize: Tokens.fontSm,
              fontWeight: FontWeight.w700,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: Tokens.spaceSm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: departures.isEmpty
                ? [
                    Text(
                      'No more buses today',
                      style: TextStyle(
                        fontSize: Tokens.fontSm,
                        color: palette.textSecondary,
                      ),
                    ),
                  ]
                : departures
                      .map(
                        (d) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Tokens.spaceSm,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              Tokens.radiusSm,
                            ),
                          ),
                          child: Text(
                            d.display,
                            style: TextStyle(
                              fontSize: Tokens.fontSm,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      )
                      .toList(),
          ),
        ],
      ),
    );
  }
}
