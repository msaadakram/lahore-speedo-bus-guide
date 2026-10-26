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

/// StopDetailScreen — every line that serves a stop and its next departures.
class StopDetailScreen extends ConsumerStatefulWidget {
  const StopDetailScreen({required this.args, super.key});

  final StopDetailArgs args;

  @override
  ConsumerState<StopDetailScreen> createState() => _StopDetailScreenState();
}

class _StopDetailScreenState extends ConsumerState<StopDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(routesDataProvider);
    final routes = data.valueOrNull?.routes ?? const <BusRoute>[];
    final key = widget.args.stopName.trim().toLowerCase();
    if (data.isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: AppCanvas(
          child: Column(
            children: [
              AppPageHeader(
                title: widget.args.stopName,
                subtitle: 'Loading lines…',
                onBack: () => Navigator.of(context).pop(),
                bottomRadius: 36,
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
                title: widget.args.stopName,
                subtitle: 'Data unavailable',
                onBack: () => Navigator.of(context).pop(),
                bottomRadius: 36,
              ),
              Expanded(
                child: EmptyState(
                  icon: AppIcons.alertTriangle,
                  title: 'Stop data unavailable',
                  message:
                      'The bundled stop and route dataset could not be loaded.',
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
    final stop = StopRepository.instance.byKey(key);
    final lines = stop == null
        ? <BusRoute>[]
        : StopRepository.instance
              .routesFor(stop.id)
              .map(
                (ref) => routes
                    .where((route) => route.id == ref.routeId)
                    .firstOrNull,
              )
              .whereType<BusRoute>()
              .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppCanvas(
        child: Column(
          children: [
            AppPageHeader(
              title: stop?.name ?? 'Stop',
              subtitle:
                  '${lines.length} ${lines.length == 1 ? 'line' : 'lines'} serving this stop',
              onBack: () => Navigator.of(context).pop(),
              bottomRadius: 36,
              trailing: AppGlassButton(
                icon: AppIcons.map,
                tooltip: 'View on map',
                size: 38,
                iconSize: 20,
                onPressed: () => Navigator.of(context).pushNamed(
                  Routes.map,
                  arguments: MapArgs(stopId: key, title: stop?.name),
                ),
              ),
            ),
            Expanded(
              child: lines.isEmpty
                  ? const EmptyState(
                      icon: AppIcons.bus,
                      title: 'No lines found',
                      message: 'No bundled route currently lists this stop.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        Tokens.spaceMd,
                        AppSpacing.screen,
                        Tokens.spaceXl,
                      ),
                      itemCount: lines.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: Tokens.spaceSm),
                      itemBuilder: (context, index) =>
                          _LineCard(route: lines[index]),
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
      radius: Tokens.shapeXl,
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppPressable(
            onPressed: () => Navigator.of(context).pushNamed(
              Routes.routeDetail,
              arguments: RouteDetailArgs(routeId: route.id, color: route.color),
            ),
            borderRadius: BorderRadius.circular(Tokens.shapeLg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(Tokens.shapeMd),
                    border: Border.all(color: color.withValues(alpha: .30)),
                  ),
                  child: BusIcon(
                    category: route.category,
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
                        route.name,
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
          Row(
            children: [
              Icon(AppIcons.clock, size: 14, color: palette.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Next departures',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Tokens.fontSm,
                    fontWeight: FontWeight.w800,
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ],
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
                        fontWeight: FontWeight.w600,
                        color: palette.textSecondary,
                      ),
                    ),
                  ]
                : [
                    for (final departure in departures)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Tokens.spaceSm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(Tokens.shapePill),
                        ),
                        child: Text(
                          departure.display,
                          style: TextStyle(
                            fontSize: Tokens.fontSm,
                            fontWeight: FontWeight.w800,
                            color: palette.text,
                          ),
                        ),
                      ),
                  ],
          ),
        ],
      ),
    );
  }
}
