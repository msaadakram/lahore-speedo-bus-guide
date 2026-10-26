import 'dart:convert' as convert;

import 'package:flutter/services.dart' show rootBundle;

import '../models/bus_stop.dart';
import '../models/category.dart';
import '../models/route.dart';

/// Loads the embedded GTFS dataset and exposes the derived indexes used by the
/// screens. Everything is in-memory and offline — the original app has no
/// network data source.
class RoutesRepository {
  RoutesRepository._();

  static final RoutesRepository instance = RoutesRepository._();

  bool _loaded = false;
  List<BusRoute> _routes = const [];
  List<RouteCategory> _categories = const [];
  Map<String, BusRoute> _routesById = <String, BusRoute>{};
  Map<String, BusStop> _stopsById = <String, BusStop>{};
  List<BusStop> _allStops = const [];
  Map<String, List<String>> _stopRoutes = <String, List<String>>{};

  bool get isLoaded => _loaded;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/routes.json');
    final decoded = convert.json.decode(raw) as Map<String, dynamic>;

    _categories = (decoded['categories'] as List<dynamic>)
        .map((e) => RouteCategory.fromJson(e as Map<String, dynamic>))
        .toList();
    _routes = (decoded['routes'] as List<dynamic>)
        .map((e) => BusRoute.fromJson(e as Map<String, dynamic>))
        .toList();

    _routesById = {for (final r in _routes) r.id: r};

    // Stop index: unique stop id -> BusStop; stop id -> route ids that call it.
    final stops = <String, BusStop>{};
    final stopRoutes = <String, List<String>>{};
    for (final route in _routes) {
      for (final c in route.coords) {
        stopRoutes.putIfAbsent(c.id, () => <String>[]).add(route.id);
        stops[c.id] = BusStop(
          id: c.id,
          name: c.name,
          latitude: c.latitude,
          longitude: c.longitude,
          routes: stopRoutes[c.id]!,
        );
      }
    }
    _stopsById = stops;
    _allStops = stops.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _stopRoutes = stopRoutes;
    for (final e in stopRoutes.entries) {
      e.value.sort((a, b) {
        final ra = _routesById[a]!;
        final rb = _routesById[b]!;
        return ra.name.compareTo(rb.name);
      });
    }
    _loaded = true;
  }

  List<BusRoute> get routes => _routes;
  List<RouteCategory> get categories => _categories;
  List<BusStop> get stops => _allStops;

  BusRoute? routeById(String id) => _routesById[id];
  BusStop? stopById(String id) => _stopsById[id];

  /// Safe before [ensureLoaded] completes: screens can render an empty state
  /// instead of tripping a late-initialisation error.
  List<String> routesForStop(String stopId) =>
      _loaded ? List.unmodifiable(_stopRoutes[stopId] ?? const []) : const [];

  RouteCategory? categoryByKey(String key) =>
      _categories.where((c) => c.key == key).firstOrNull;

  /// `categoryOf(shortName)` — Metro module 718.
  static String categoryOf(String shortName) {
    if (shortName.startsWith('Speedo')) return 'speedo';
    if (shortName.startsWith('Metro')) return 'metro';
    if (shortName.startsWith('Orange')) return 'orangeLine';
    return 'electric';
  }

  /// `getCategoryColor(key)` — Metro module 715.
  static String getCategoryColor(String key) {
    return switch (key) {
      'speedo' => '#e12221',
      'metro' => '#358437',
      'orangeLine' => '#e29109',
      'electric' => '#358437',
      _ => '#fc3b38',
    };
  }

  /// `getCategoryLabel(key)`.
  static String getCategoryLabel(String key) {
    return switch (key) {
      'speedo' => 'Speedo',
      'metro' => 'Metro',
      'orangeLine' => 'Orange Line',
      'electric' => 'Electric',
      _ => 'All',
    };
  }
}
