import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;

import '../../app/router.dart';
import '../../app/theme/app_palette.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_tokens.dart';
import '../../core/services/location_service.dart';
import '../../data/models/route.dart';
import '../../data/repositories/routes_repository.dart';
import '../../data/repositories/stop_repository.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/route_widgets.dart';

/// NearbyScreen (Metro module 722).
enum NearbyStatus { idle, loading, denied, locationOff, error, done }

class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key});

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  NearbyStatus _status = NearbyStatus.idle;
  List<NearbyStop> _stops = const [];

  @override
  void initState() {
    super.initState();
    // Ensure the stop index is available before the location lookup.
    StopRepository.instance.ensureLoaded().then((_) {
      if (mounted) _locate();
    });
  }

  Future<void> _locate() async {
    setState(() => _status = NearbyStatus.loading);
    final position = await ref.read(locationServiceProvider).currentLocation();
    if (!mounted) return;
    if (position == null) {
      final enabled = await GeolocatorLocator.isEnabled();
      final perm = await PermissionsLocator.status();
      if (!enabled) {
        setState(() => _status = NearbyStatus.locationOff);
      } else if (perm == false) {
        setState(() => _status = NearbyStatus.denied);
      } else {
        setState(() => _status = NearbyStatus.error);
      }
      return;
    }
    final found = StopRepository.instance.nearby(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    if (!mounted) return;
    setState(() {
      _stops = found.take(15).toList();
      _status = NearbyStatus.done;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final insets = MediaQuery.paddingOf(context);

    return Scaffold(
      body: ColoredBox(
        color: palette.background,
        child: Column(
          children: [
            // ------------------------------------------------------ header
            Container(
              decoration: BoxDecoration(
                gradient: palette.heroGradient,
                boxShadow: palette.softShadow,
              ),
              padding: EdgeInsets.only(
                left: AppSpacing.screen,
                right: AppSpacing.screen,
                top: insets.top + Tokens.spaceMd,
                bottom: Tokens.spaceLg,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nearby Stops',
                        style: TextStyle(
                          fontSize: Tokens.fontXxl,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Bus stops close to you',
                        style: TextStyle(
                          fontSize: Tokens.fontLg,
                          fontWeight: FontWeight.w600,
                          color: Color(0xE6FFFFFF),
                        ),
                      ),
                    ],
                  ),
                  AppPressable(
                    onPressed: _status == NearbyStatus.loading ? null : _locate,
                    borderless: true,
                    rippleColor: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        AppIcons.reload,
                        size: 24,
                        color: Colors.white.withValues(
                          alpha: _status == NearbyStatus.loading ? 0.5 : 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ------------------------------------------------------ body
            Expanded(child: _body(palette)),
          ],
        ),
      ),
    );
  }

  Widget _body(AppPalette palette) {
    switch (_status) {
      case NearbyStatus.loading:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: palette.primary),
              const SizedBox(height: Tokens.spaceMd),
              Text(
                'Finding your location…',
                style: TextStyle(color: palette.textSecondary),
              ),
            ],
          ),
        );

      case NearbyStatus.denied:
        return _messageState(
          palette,
          message: 'Location permission is needed to find stops near you.',
          buttonLabel: 'Open App Settings',
          onButton: openAppSettings,
        );

      case NearbyStatus.locationOff:
        return _messageState(
          palette,
          message: 'Location is turned off on your device. Turn it on to find stops near you.',
          buttonLabel: 'Open Location Settings',
          onButton: openLocationSettings,
        );

      case NearbyStatus.error:
        return _messageState(
          palette,
          message: 'Could not get your location. Please try again.',
          buttonLabel: 'Try Again',
          onButton: _locate,
        );

      case NearbyStatus.idle:
      case NearbyStatus.done:
        break;
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: Tokens.spaceXl),
      itemCount: _stops.length + 1,
      itemBuilder: (context, i) {
        if (i == _stops.length) {
          // ListFooterComponent — only present when the list is shown.
          return Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.screen,
              right: AppSpacing.screen,
              top: Tokens.spaceMd,
            ),
            child: Text(
              'Tap any stop for directions · Sorted by walking distance',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Tokens.fontSm,
                fontStyle: FontStyle.italic,
                color: palette.textSecondary,
              ),
            ),
          );
        }
        return _StopRow(stop: _stops[i]);
      },
    );
  }

  Widget _messageState(
    AppPalette palette, {
    required String message,
    required String buttonLabel,
    required VoidCallback onButton,
  }) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(Tokens.spaceXl),
        child: Column(
          children: [
            Icon(AppIcons.mapMarker, size: 32, color: palette.textSecondary),
            const SizedBox(height: Tokens.spaceMd),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Tokens.fontBase,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: Tokens.spaceXl),
            AppFilledDarkButton(label: buttonLabel, onPressed: onButton),
            AppTextButton(label: 'Try Again', onPressed: _locate),
          ],
        ),
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({required this.stop});

  final NearbyStop stop;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final entry = stop;
    final stopInfo = stop.stop;
    final meters = entry.distanceMeters;
    final walkMinutes = _walkMinutes(meters);

    return AppPressable(
      onPressed: () => Navigator.of(context).pushNamed(
        Routes.stopDetail,
        arguments: StopDetailArgs(stopName: stopInfo.name),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: Tokens.spaceXs,
        ),
        padding: const EdgeInsets.all(Tokens.spaceMd),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(Tokens.radiusLg),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Tokens.radiusMd),
              ),
              child: Icon(AppIcons.stop, size: 20, color: palette.primary),
            ),
            const SizedBox(width: Tokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stopInfo.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Tokens.fontBase,
                      fontWeight: FontWeight.w700,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        AppIcons.directionsWalk,
                        size: 14,
                        color: palette.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _formatDistance(meters),
                        style: TextStyle(
                          fontSize: Tokens.fontSm,
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        ' -- ',
                        style: TextStyle(
                          fontSize: Tokens.fontSm,
                          color: palette.textSecondary,
                        ),
                      ),
                      Icon(
                        AppIcons.clock,
                        size: 14,
                        color: palette.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$walkMinutes min',
                        style: TextStyle(
                          fontSize: Tokens.fontSm,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Tokens.spaceSm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final routeId in stopInfo.routes.take(4))
                        RouteChipSmall(
                          route: RoutesRepository.instance.routeById(routeId),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(AppIcons.chevronRight, size: 18, color: palette.textSecondary),
          ],
        ),
      ),
    );
  }
}

class RouteChipSmall extends StatelessWidget {
  const RouteChipSmall({required this.route, super.key});

  final BusRoute? route;

  @override
  Widget build(BuildContext context) {
    if (route == null) return const SizedBox.shrink();
    return RouteChip(route: route!);
  }
}

int _walkMinutes(int meters) {
  final v = meters / 80;
  return v < 1 ? 1 : v.round();
}

String _formatDistance(int meters) {
  if (meters < 1000) return '$meters m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

/// Thin façade so the screen does not import `geolocator` directly.
class GeolocatorLocator {
  static Future<bool> isEnabled() => geo.Geolocator.isLocationServiceEnabled();
}

class PermissionsLocator {
  static Future<bool> status() async {
    final p = await geo.Geolocator.checkPermission();
    return p == geo.LocationPermission.always ||
        p == geo.LocationPermission.whileInUse;
  }
}

Future<void> openAppSettings() => geo.Geolocator.openAppSettings();
Future<void> openLocationSettings() => geo.Geolocator.openLocationSettings();
