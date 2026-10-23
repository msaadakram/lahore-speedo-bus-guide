import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahore_speedo_bus_guide/data/models/route.dart';
import 'package:lahore_speedo_bus_guide/data/repositories/stop_repository.dart';

Future<List<BusRoute>> _loadRoutes() async {
  final raw = await rootBundle.loadString('assets/data/routes.json');
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return (decoded['routes'] as List)
      .cast<Map<String, dynamic>>()
      .map(BusRoute.fromJson)
      .toList();
}

String _categoryOf(String shortName) {
  if (shortName.startsWith('Speedo')) return 'speedo';
  if (shortName.startsWith('Metro')) return 'metro';
  if (shortName.startsWith('Orange')) return 'orangeLine';
  return 'electric';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bundled dataset (assets/data/routes.json)', () {
    late List<BusRoute> routes;

    setUpAll(() async {
      routes = await _loadRoutes();
    });

    test('loads the 28 recovered routes', () {
      expect(routes, hasLength(28));
    });

    test('every route is internally complete', () {
      for (final r in routes) {
        expect(r.id, isNotEmpty);
        expect(r.name, isNotEmpty);
        expect(r.stationAddress, isNotEmpty);
        expect(r.category, isNotEmpty);
        expect(r.fare, isNotEmpty);
        expect(r.color, matches(RegExp(r'^#[0-9A-Fa-f]{6}$')));
        expect(r.stops, isNotEmpty);
        expect(r.stopIds.length, r.stops.length);
        expect(r.coords.length, r.stops.length);
        expect(r.operatingHours, matches(RegExp(r'AM|PM')));
        expect(r.frequency, contains('minutes'));
      }
    });

    test('category counts match the recovered CATEGORIES', () {
      final byCategory = <String, int>{};
      for (final r in routes) {
        byCategory[r.category] = (byCategory[r.category] ?? 0) + 1;
      }
      expect(byCategory['speedo'], 23);
      expect(byCategory['metro'], 1);
      expect(byCategory['orangeLine'], 1);
      expect(byCategory['electric'], 3);
    });

    test('categoryOf reproduces the original rule for every route', () {
      for (final r in routes) {
        expect(_categoryOf(r.name), r.category);
      }
    });

    test('stop index is built from normalised stop names', () {
      final map = <String, List<int>>{};
      for (final route in routes) {
        for (var i = 0; i < route.stops.length; i++) {
          final key = route.stops[i].trim().toLowerCase();
          if (key.isEmpty) continue;
          map.putIfAbsent(key, () => <int>[]).add(i);
        }
      }
      expect(map.keys.length, greaterThan(300));
      expect(map.containsKey('bahria town'), isTrue);
      expect(map.containsKey('bahria town '.trim()), isTrue);
      // Every key is lower-case with no surrounding whitespace.
      for (final k in map.keys) {
        expect(k, k.trim().toLowerCase());
      }
    });

    test('haversine distance is sane for Lahore coordinates', () {
      final d = haversineMeters(31.5, 74.3, 31.6, 74.4);
      expect(d, greaterThan(9000));
      expect(d, lessThan(16000));
      expect(haversineMeters(0, 0, 0, 0), closeTo(0, 1e-9));
    });

    test('walkMinutesFor uses 80 m/min with a 1-minute floor', () {
      expect(walkMinutesFor(40), 1);
      expect(walkMinutesFor(160), 2);
      expect(walkMinutesFor(800), 10);
    });
  });
}
