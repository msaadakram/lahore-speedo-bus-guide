import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bus_stop.dart';
import '../models/category.dart';
import '../models/route.dart';
import 'routes_repository.dart';

/// Loaded-state notifier so widgets can react to data availability.
class RoutesData {
  const RoutesData({
    required this.routes,
    required this.categories,
    required this.stops,
    this.isLoading = false,
    this.error,
  });

  const RoutesData.loading()
    : this(
        routes: const [],
        categories: const [],
        stops: const [],
        isLoading: true,
      );

  const RoutesData.failure(Object error)
    : this(
        routes: const [],
        categories: const [],
        stops: const [],
        error: error,
      );

  final List<BusRoute> routes;
  final List<RouteCategory> categories;
  final List<BusStop> stops;
  final bool isLoading;
  final Object? error;

  BusRoute? routeById(String id) => routes.where((r) => r.id == id).firstOrNull;

  RouteCategory? categoryByKey(String key) =>
      categories.where((c) => c.key == key).firstOrNull;

  List<String> routesForStop(String stopId) {
    final out = <String>[];
    for (final r in routes) {
      if (r.containsStop(stopId)) out.add(r.id);
    }
    out.sort((a, b) {
      final ra = routeById(a)!;
      final rb = routeById(b)!;
      return ra.name.compareTo(rb.name);
    });
    return out;
  }
}

final routesDataProvider = FutureProvider<RoutesData>((ref) async {
  final repo = RoutesRepository.instance;
  await repo.ensureLoaded();
  return RoutesData(
    routes: repo.routes,
    categories: repo.categories,
    stops: repo.stops,
  );
});
