import 'dart:math' as math;

import '../models/bus_stop.dart';
import 'routes_repository.dart';

/// Stop index rebuilt from the embedded routes.
///
/// Original equivalent (`stops.ts`, Metro module 734):
///
///   const map = new Map();
///   ROUTES.forEach(route => route.stops.forEach((name, index) => {
///     const key = (name ?? '').trim().toLowerCase();
///     if (!key) return;
///     const coord = route.coords[index] ?? null;
///     if (!map.has(key)) map.set(key, { key, name, latitude, longitude, routes: [] });
///     map.get(key).routes.push({ routeId: route.id, index });
///   }));
///   export const ALL_STOPS = [...map.values()].sort((a,b) => a.name.localeCompare(b.name));
///
///   export function searchStops(q) {
///     if (!q || !q.trim()) return ALL_STOPS;
///     const k = q.trim().toLowerCase();
///     return ALL_STOPS.filter(s => s.key.includes(k));
///   }
class StopRepository {
  StopRepository._();
  static final StopRepository instance = StopRepository._();

  bool _loaded = false;
  List<BusStop> _all = const [];
  final Map<String, List<StopRouteRef>> _routesByStop = {};

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await RoutesRepository.instance.ensureLoaded();
    final routes = RoutesRepository.instance.routes;

    final byKey = <String, BusStop>{};
    for (final route in routes) {
      for (var i = 0; i < route.stops.length; i++) {
        final name = route.stops[i];
        final key = name.trim().toLowerCase();
        if (key.isEmpty) {
          continue;
        }
        final coord = i < route.coords.length ? route.coords[i] : null;
        _routesByStop
            .putIfAbsent(key, () => <StopRouteRef>[])
            .add(StopRouteRef(routeId: route.id, index: i));
        byKey[key] = BusStop(
          id: key,
          name: name,
          latitude: coord?.latitude ?? 0,
          longitude: coord?.longitude ?? 0,
          routes: _routesByStop[key]!.map((r) => r.routeId).toList(),
        );
      }
    }

    _all = byKey.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _loaded = true;
  }

  List<BusStop> get allStops => _all;

  BusStop? byKey(String key) => _all.where((s) => s.id == key).firstOrNull;

  List<StopRouteRef> routesFor(String stopKey) =>
      List.unmodifiable(_routesByStop[stopKey] ?? const []);

  /// `searchStops(query)`
  List<BusStop> search(String query) {
    if (query.trim().isEmpty) return _all;
    final k = query.trim().toLowerCase();
    return _all.where((s) => s.id.contains(k)).toList();
  }

  /// Stops that carry real coordinates.
  List<BusStop> get geoStops =>
      _all.where((s) => s.latitude != 0 || s.longitude != 0).toList();

  /// Stops within [radiusMeters] of a point, sorted by distance ascending.
  List<NearbyStop> nearby({
    required double latitude,
    required double longitude,
    int radiusMeters = 600,
  }) {
    final out = <NearbyStop>[];
    for (final s in geoStops) {
      final d = haversineMeters(latitude, longitude, s.latitude, s.longitude);
      if (d <= radiusMeters) {
        out.add(NearbyStop(stop: s, distanceMeters: d.round()));
      }
    }
    out.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return out;
  }
}

class NearbyStop {
  const NearbyStop({required this.stop, required this.distanceMeters});

  final BusStop stop;
  final int distanceMeters;
}

class StopRouteRef {
  const StopRouteRef({required this.routeId, required this.index});

  final String routeId;
  final int index;
}

/// Great-circle distance in metres — identical formula to the original
/// `haversine` helper (2 · R · atan2(√a, √(1−a)), R = 6 371 000 m).
double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371000.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLon = (lon2 - lon1) * math.pi / 180;
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

/// Re-export so other layers can avoid importing `dart:math`.
int walkMinutesFor(int meters) => math.max(1, (meters / 80).round());
