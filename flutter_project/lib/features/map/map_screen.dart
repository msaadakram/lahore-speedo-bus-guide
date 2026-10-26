import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/router.dart';
import '../../app/theme/app_palette.dart';
import '../../app/theme/app_tokens.dart';
import '../../core/services/link_launcher.dart';
import '../../data/repositories/routes_repository.dart';
import '../../data/repositories/stop_repository.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/route_widgets.dart';

/// MapScreen — OpenStreetMap-powered route and stop viewer.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({required this.args, super.key});

  final MapArgs args;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late final MapController _controller;
  String _mapType = 'standard';
  int? _selectedStopIndex;

  static const _lahoreInitial = LatLng(31.5497, 74.3436);

  List<_MapStop> get _stops {
    if (widget.args.routeId != null) {
      final route = RoutesRepository.instance.routeById(widget.args.routeId!);
      if (route != null) {
        return [
          for (
            var i = 0;
            i < route.coords.length && i < route.stops.length;
            i++
          )
            _MapStop(
              name: route.stops[i],
              position: LatLng(
                route.coords[i].latitude,
                route.coords[i].longitude,
              ),
              routeId: route.id,
              isTerminus: i == 0 || i == route.coords.length - 1,
            ),
        ];
      }
    }
    if (widget.args.stopId != null) {
      final stop = StopRepository.instance.byKey(widget.args.stopId!);
      if (stop != null) {
        return [
          _MapStop(
            name: stop.name,
            position: LatLng(stop.latitude, stop.longitude),
            isTerminus: true,
          ),
        ];
      }
    }
    return StopRepository.instance.geoStops.take(80).map((stop) {
      return _MapStop(
        name: stop.name,
        position: LatLng(stop.latitude, stop.longitude),
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _controller = MapController();
  }

  void _fitAll() {
    if (_stops.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(
      _stops.map((stop) => stop.position).toList(),
    );
    _controller.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(60, 90, 60, 120),
      ),
    );
  }

  Future<void> _openDirections(double latitude, double longitude) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=transit',
    );
    final opened = await openLink(url.toString());
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not open directions.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final stops = _stops;
    final route = widget.args.routeId == null
        ? null
        : RoutesRepository.instance.routeById(widget.args.routeId!);
    final lineColor = route == null
        ? palette.primary
        : parseRouteColor(route.color);
    final selected =
        _selectedStopIndex == null || _selectedStopIndex! >= stops.length
        ? null
        : stops[_selectedStopIndex!];
    final center = stops.isEmpty
        ? _lahoreInitial
        : LatLng(
            (stops.map((stop) => stop.position.latitude).reduce(math.min) +
                    stops
                        .map((stop) => stop.position.latitude)
                        .reduce(math.max)) /
                2,
            (stops.map((stop) => stop.position.longitude).reduce(math.min) +
                    stops
                        .map((stop) => stop.position.longitude)
                        .reduce(math.max)) /
                2,
          );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppCanvas(
        child: Column(
          children: [
            AppPageHeader(
              title: route?.name ?? widget.args.title ?? 'All Bus Stops',
              subtitle: stops.length == 1
                  ? 'Selected stop'
                  : '${stops.length} stops on the map',
              onBack: () => Navigator.of(context).pop(),
              bottomRadius: 32,
              padding: EdgeInsets.only(
                left: Tokens.spaceMd,
                right: Tokens.spaceSm,
                top: MediaQuery.paddingOf(context).top + Tokens.spaceSm,
                bottom: Tokens.spaceSm,
              ),
              trailing: AppGlassButton(
                icon: _mapType == 'standard'
                    ? AppIcons.mapMarkerAlt
                    : AppIcons.map,
                tooltip: _mapType == 'standard'
                    ? 'Switch to satellite'
                    : 'Switch to street map',
                size: 38,
                iconSize: 20,
                onPressed: () => setState(
                  () => _mapType = _mapType == 'standard'
                      ? 'satellite'
                      : 'standard',
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _controller,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: stops.length > 1 ? 12 : 15,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _mapType == 'standard'
                            ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
                            : 'https://server.arcgisonline.com/ArcGIS/rest/services/'
                                  'World_Imagery/MapServer/tile/{z}/{y}/{x}',
                        userAgentPackageName: 'com.lahorebus',
                        maxZoom: 18,
                      ),
                      if (stops.length > 1)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: stops
                                  .map((stop) => stop.position)
                                  .toList(),
                              strokeWidth: 5,
                              color: lineColor.withValues(alpha: .78),
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          for (var i = 0; i < stops.length; i++)
                            Marker(
                              point: stops[i].position,
                              width: stops[i].isTerminus ? 24 : 18,
                              height: stops[i].isTerminus ? 24 : 18,
                              child: Semantics(
                                label: stops[i].name,
                                button: true,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedStopIndex = i),
                                  child: Container(
                                    width: stops[i].isTerminus ? 24 : 14,
                                    height: stops[i].isTerminus ? 24 : 14,
                                    decoration: BoxDecoration(
                                      color: stops[i].isTerminus
                                          ? lineColor
                                          : palette.card,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: lineColor,
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: .24,
                                          ),
                                          blurRadius: 7,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const _AttributionBadge(),
                    ],
                  ),
                  Positioned(
                    right: Tokens.spaceMd,
                    bottom: Tokens.spaceLg,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MapFab(
                          icon: AppIcons.map,
                          label: 'Get Direction',
                          onTap: () {
                            final cameraCenter = _controller.camera.center;
                            _openDirections(
                              cameraCenter.latitude,
                              cameraCenter.longitude,
                            );
                          },
                        ),
                        const SizedBox(height: Tokens.spaceSm),
                        _MapFab(
                          icon: AppIcons.fitScreen,
                          label: 'Fit',
                          onTap: _fitAll,
                        ),
                      ],
                    ),
                  ),
                  if (selected != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _StopSheet(
                        stop: selected,
                        onClose: () =>
                            setState(() => _selectedStopIndex = null),
                        onOpenStop: () => Navigator.of(context).pushNamed(
                          Routes.stopDetail,
                          arguments: StopDetailArgs(stopName: selected.name),
                        ),
                        onDirections: () => _openDirections(
                          selected.position.latitude,
                          selected.position.longitude,
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

class _MapStop {
  const _MapStop({
    required this.name,
    required this.position,
    this.routeId,
    this.isTerminus = false,
  });

  final String name;
  final LatLng position;
  final String? routeId;
  final bool isTerminus;
}

/// Compact, shrinkable OSM attribution. `SimpleAttributionWidget` uses a
/// non-wrapping row that overflows at large font scales.
class _AttributionBadge extends StatelessWidget {
  const _AttributionBadge();

  static const _copyrightUrl = 'https://www.openstreetmap.org/copyright';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: GestureDetector(
            onTap: () => openLink(_copyrightUrl),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .88),
                borderRadius: BorderRadius.circular(Tokens.radiusSm),
              ),
              child: const Text(
                '© OpenStreetMap contributors',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  const _MapFab({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return AppPressable(
      onPressed: onTap,
      borderRadius: BorderRadius.circular(Tokens.shapePill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Tokens.spaceMd,
          vertical: Tokens.spaceSm,
        ),
        decoration: BoxDecoration(
          color: palette.card.withValues(alpha: .96),
          borderRadius: BorderRadius.circular(Tokens.shapePill),
          border: Border.all(color: palette.border),
          boxShadow: palette.softShadow,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: palette.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: Tokens.fontSm,
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StopSheet extends StatelessWidget {
  const _StopSheet({
    required this.stop,
    required this.onClose,
    required this.onOpenStop,
    required this.onDirections,
  });

  final _MapStop stop;
  final VoidCallback onClose;
  final VoidCallback onOpenStop;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final lines = StopRepository.instance.routesFor(stop.name.toLowerCase());
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        border: Border(top: BorderSide(color: palette.border)),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Tokens.shapeXl),
        ),
        boxShadow: palette.liftedShadow,
      ),
      padding: const EdgeInsets.all(Tokens.spaceMd),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(Tokens.shapePill),
                ),
              ),
            ),
            const SizedBox(height: Tokens.spaceSm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    stop.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Tokens.fontLg,
                      fontWeight: FontWeight.w900,
                      color: palette.text,
                    ),
                  ),
                ),
                AppPressable(
                  onPressed: onClose,
                  borderless: true,
                  borderRadius: BorderRadius.circular(18),
                  child: Icon(
                    AppIcons.close,
                    size: 20,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Every ${DepartureLabel.forStop(stop.name)}',
              style: TextStyle(
                fontSize: Tokens.fontSm,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: Tokens.spaceMd),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Get Direction',
                    icon: AppIcons.directions,
                    onPressed: onDirections,
                  ),
                ),
                const SizedBox(width: Tokens.spaceSm),
                Expanded(
                  child: AppButton(
                    label: 'Stop Info',
                    icon: AppIcons.stop,
                    onPressed: onOpenStop,
                    muted: true,
                  ),
                ),
              ],
            ),
            if (lines.isNotEmpty) ...[
              const SizedBox(height: Tokens.spaceSm),
              Text(
                '${lines.length} ${lines.length == 1 ? 'line' : 'lines'} serve this stop',
                style: TextStyle(
                  fontSize: Tokens.fontXs,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small helper so the sheet can print a generic frequency label.
abstract final class DepartureLabel {
  const DepartureLabel._();

  static String forStop(String stopName) {
    final refs = StopRepository.instance.routesFor(stopName.toLowerCase());
    if (refs.isEmpty) return '15 minutes';
    final route = RoutesRepository.instance.routeById(refs.first.routeId);
    return route?.frequency ?? '15 minutes';
  }
}
