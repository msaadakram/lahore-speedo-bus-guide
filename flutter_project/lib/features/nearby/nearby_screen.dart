import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;

import '../../app/router.dart';
import '../../app/theme/app_palette.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_tokens.dart';
import '../../core/services/location_service.dart';
import '../../data/models/route.dart';
import '../../data/repositories/departures.dart';
import '../../data/repositories/routes_repository.dart';
import '../../data/repositories/stop_repository.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/route_widgets.dart';

/// NearbyScreen — stops closest to the device, with permission-aware states.
enum NearbyStatus { idle, loading, denied, locationOff, error, done }

class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key});

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  NearbyStatus _status = NearbyStatus.idle;
  List<NearbyStop> _stops = const [];

  static const int nearbyRadiusMeters = 1200;

  @override
  void initState() {
    super.initState();
    unawaited(_prepareAndLocate());
  }

  Future<void> _prepareAndLocate() async {
    try {
      await StopRepository.instance.ensureLoaded();
    } catch (_) {
      // The launch gate normally warms the dataset. If it failed, still try:
      // an empty stop index is better than blocking the permission flow.
    }
    if (mounted) await _locate();
  }

  Future<void> _locate() async {
    if (!mounted) return;
    setState(() => _status = NearbyStatus.loading);

    final position = await ref.read(locationServiceProvider).currentLocation();
    if (!mounted) return;
    if (position == null) {
      await _syncFailureState();
      return;
    }

    final found = StopRepository.instance.nearby(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusMeters: nearbyRadiusMeters,
    );
    if (!mounted) return;
    setState(() {
      _stops = found.take(20).toList();
      _status = NearbyStatus.done;
    });
  }

  Future<void> _syncFailureState() async {
    try {
      final enabled = await GeolocatorLocator.isEnabled();
      final permission = await PermissionsLocator.status();
      if (!mounted) return;
      setState(() {
        if (!enabled) {
          _status = NearbyStatus.locationOff;
        } else if (!permission) {
          _status = NearbyStatus.denied;
        } else {
          _status = NearbyStatus.error;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = NearbyStatus.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppCanvas(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Nearby Stops',
              subtitle: 'Bus stops close to you',
              bottomRadius: 36,
              trailing: AppGlassButton(
                icon: AppIcons.reload,
                tooltip: 'Refresh location',
                onPressed: _status == NearbyStatus.loading ? null : _locate,
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: switch (_status) {
        NearbyStatus.idle => const _LoadingList(key: ValueKey('loading')),
        NearbyStatus.loading => const _LoadingList(key: ValueKey('loading')),
        NearbyStatus.denied => _MessageState(
          key: const ValueKey('denied'),
          icon: AppIcons.mapMarker,
          title: 'Location permission needed',
          message: 'Allow location access so the guide can find stops within walking distance.',
          buttonLabel: 'Open App Settings',
          onButton: openAppSettings,
          onRetry: _locate,
        ),
        NearbyStatus.locationOff => _MessageState(
          key: const ValueKey('location-off'),
          icon: AppIcons.mapMarkerAlt,
          title: 'Location is off',
          message: 'Turn on device location, then refresh to see the closest bus stops.',
          buttonLabel: 'Open Location Settings',
          onButton: openLocationSettings,
          onRetry: _locate,
        ),
        NearbyStatus.error => _MessageState(
          key: const ValueKey('error'),
          icon: AppIcons.alertTriangle,
          title: 'Could not get your location',
          message:
              'Your device could not provide a position. Please try again.',
          buttonLabel: 'Try Again',
          onButton: _locate,
          onRetry: _locate,
          showSecondaryAction: false,
        ),
        NearbyStatus.done =>
          _stops.isEmpty
              ? EmptyState(
                  key: const ValueKey('empty'),
                  icon: AppIcons.mapMarker,
                  title: 'No stops nearby',
                  message:
                      'No stop is within $nearbyRadiusMeters metres. Try another area or search for a stop.',
                  action: AppButton(
                    label: 'Refresh',
                    icon: AppIcons.reload,
                    expand: false,
                    onPressed: _locate,
                  ),
                )
              : _NearbyList(key: const ValueKey('stops'), stops: _stops),
      },
    );
  }
}

class _NearbyList extends StatelessWidget {
  const _NearbyList({required this.stops, super.key});

  final List<NearbyStop> stops;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        Tokens.spaceMd,
        AppSpacing.screen,
        Tokens.spaceXl,
      ),
      itemCount: stops.length + 1,
      itemBuilder: (context, index) {
        if (index == stops.length) {
          final palette = AppPaletteScope.paletteOf(context);
          return Padding(
            padding: const EdgeInsets.only(top: Tokens.spaceMd),
            child: Text(
              'Tap any stop for details · Sorted by walking distance',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Tokens.fontSm,
                fontStyle: FontStyle.italic,
                color: palette.textSecondary,
              ),
            ),
          );
        }
        return _StopCard(stop: stops[index]);
      },
    );
  }
}

class _StopCard extends StatelessWidget {
  const _StopCard({required this.stop});

  final NearbyStop stop;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final stopInfo = stop.stop;
    final meters = stop.distanceMeters;
    final walkMinutes = walkMinutesFor(meters);
    final distance = Departures.formatWalkDistance(meters);

    return AppCard(
      margin: const EdgeInsets.only(bottom: Tokens.spaceSm),
      radius: Tokens.shapeXl,
      elevated: true,
      child: AppPressable(
        onPressed: () => Navigator.of(context).pushNamed(
          Routes.stopDetail,
          arguments: StopDetailArgs(stopName: stopInfo.name),
        ),
        borderRadius: BorderRadius.circular(Tokens.shapeXl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: palette.heroGradient,
                borderRadius: BorderRadius.circular(Tokens.shapeMd),
                boxShadow: palette.softShadow,
              ),
              child: const Icon(AppIcons.stop, size: 24, color: Colors.white),
            ),
            const SizedBox(width: Tokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stopInfo.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Tokens.fontBase,
                      fontWeight: FontWeight.w800,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: Tokens.spaceSm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _WalkChip(
                        icon: AppIcons.directionsWalk,
                        label: '$distance · $walkMinutes min walk',
                      ),
                    ],
                  ),
                  const SizedBox(height: Tokens.spaceSm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final route
                          in stopInfo.routes
                              .take(4)
                              .map(RoutesRepository.instance.routeById)
                              .whereType<BusRoute>())
                        RouteChip(route: route),
                    ],
                  ),
                ],
              ),
            ),
            Icon(AppIcons.chevronRight, size: 20, color: palette.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _WalkChip extends StatelessWidget {
  const _WalkChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: .12),
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
              color: palette.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onButton,
    required this.onRetry,
    this.showSecondaryAction = true,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onButton;
  final VoidCallback onRetry;
  final bool showSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: EmptyState(
        icon: icon,
        title: title,
        message: message,
        action: Column(
          children: [
            AppButton(label: buttonLabel, onPressed: onButton),
            if (showSecondaryAction) ...[
              const SizedBox(height: Tokens.spaceSm),
              AppTextButton(label: 'Try Again', onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        Center(
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: Tokens.spaceMd),
              Text(
                'Finding your location…',
                style: TextStyle(color: palette.textSecondary),
              ),
            ],
          ),
        ),
        for (var i = 0; i < 5; i++)
          Container(
            height: 88,
            margin: const EdgeInsets.only(top: Tokens.spaceSm),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(Tokens.shapeXl),
              border: Border.all(color: palette.border),
            ),
          ),
      ],
    );
  }
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
