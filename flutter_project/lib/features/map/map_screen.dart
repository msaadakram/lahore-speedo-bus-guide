import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router.dart';
import '../../app/theme/app_palette.dart';
import '../../app/theme/app_tokens.dart';
import '../../data/repositories/routes_repository.dart';
import '../../data/repositories/stop_repository.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/route_widgets.dart';

/// MapScreen (Metro module 1033).
///
/// The original used `react-native-maps`; the rebuild uses `flutter_map` with
/// OpenStreetMap tiles so no Google Maps API key is required.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({required this.args, super.key});

  final MapArgs args;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _controller;
  String _mapType = 'standard';
  int? _selectedStopIndex;

  /// Lahore, ~31.55/74.34 with a delta of 0.2.
  static const _lahoreInitial = LatLng(31.5497, 74.3436);

  List<_MapStop> get _stops {
    if (widget.args.routeId != null) {
      final route = RoutesRepository.instance.routeById(widget.args.routeId!);
      if (route != null) {
        return [
          for (var i = 0; i < route.coords.length; i++)
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
    return StopRepository.instance.geoStops.take(80).map((s) {
      return _MapStop(name: s.name, position: LatLng(s.latitude, s.longitude));
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
      _stops.map((s) => s.position).toList(),
    );
    _controller.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(60, 100, 60, 120),
      ),
    );
  }

  Future<void> _openDirections(double lat, double lng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=transit',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final insets = MediaQuery.paddingOf(context);
    final stops = _stops;
    final route = widget.args.routeId == null
        ? null
        : RoutesRepository.instance.routeById(widget.args.routeId!);
    final lineColor = route == null
        ? palette.primary
        : parseRouteColor(route.color);
    final selected = _selectedStopIndex == null
        ? null
        : stops[_selectedStopIndex!];
    final center = stops.isEmpty
        ? _lahoreInitial
        : LatLng(
            stops.map((s) => s.position.latitude).reduce(math.min) +
                (stops.map((s) => s.position.latitude).reduce(math.max) -
                        stops
                            .map((s) => s.position.latitude)
                            .reduce(math.min)) /
                    2,
            stops.map((s) => s.position.longitude).reduce(math.min) +
                (stops.map((s) => s.position.longitude).reduce(math.max) -
                        stops
                            .map((s) => s.position.longitude)
                            .reduce(math.min)) /
                    2,
          );

    return Scaffold(
      body: ColoredBox(
        color: palette.background,
        child: Column(
          children: [
            // ---------------------------------------------------- header
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
              child: Row(
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
                      route?.name ?? widget.args.title ?? 'All Bus Stops',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: Tokens.fontXl,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // map type toggle
                  AppPressable(
                    onPressed: () => setState(
                      () => _mapType = _mapType == 'standard'
                          ? 'satellite'
                          : 'standard',
                    ),
                    borderless: true,
                    rippleColor: Colors.white,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Tokens.spaceSm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(Tokens.radiusFull),
                      ),
                      child: Text(
                        _mapType == 'standard' ? 'Satellite' : 'Street',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: Tokens.fontXs,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ---------------------------------------------------- map
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
                        userAgentPackageName:
                            'com.lahorebus',
                        maxZoom: 18,
                      ),
                      if (stops.length > 1)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: stops.map((s) => s.position).toList(),
                              strokeWidth: 5,
                              color: lineColor.withValues(alpha: 0.75),
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          for (var i = 0; i < stops.length; i++)
                            Marker(
                              point: stops[i].position,
                              width: 22,
                              height: 22,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedStopIndex = i),
                                child: Container(
                                  width: stops[i].isTerminus ? 22 : 14,
                                  height: stops[i].isTerminus ? 22 : 14,
                                  decoration: BoxDecoration(
                                    color: stops[i].isTerminus
                                        ? lineColor
                                        : palette.card,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: lineColor,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // floating actions
                  Positioned(
                    right: Tokens.spaceMd,
                    bottom: Tokens.spaceMd,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MapFab(
                          icon: AppIcons.map,
                          label: 'Get Direction',
                          onTap: () {
                            final c = _controller.camera.center;
                            _openDirections(c.latitude, c.longitude);
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

                  // bottom sheet for the selected stop
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
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Tokens.spaceMd,
          vertical: Tokens.spaceSm,
        ),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(Tokens.radiusFull),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: palette.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: Tokens.fontSm,
                fontWeight: FontWeight.w700,
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
          top: Radius.circular(Tokens.radiusXl),
        ),
      ),
      padding: const EdgeInsets.all(Tokens.spaceMd),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    stop.name,
                    style: TextStyle(
                      fontSize: Tokens.fontLg,
                      fontWeight: FontWeight.w700,
                      color: palette.text,
                    ),
                  ),
                ),
                AppPressable(
                  onPressed: onClose,
                  borderless: true,
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
