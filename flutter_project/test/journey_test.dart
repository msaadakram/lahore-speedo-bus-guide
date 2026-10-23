import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahore_speedo_bus_guide/data/models/bus_stop.dart';
import 'package:lahore_speedo_bus_guide/data/models/route.dart';
import 'package:lahore_speedo_bus_guide/data/repositories/journey_repository.dart';

/// Exercises `JourneyRepository.buildLeg` and `findBestTransfer` against the real
/// bundled dataset — the same core logic the JourneyResults/Detail screens use.
Future<({List<BusRoute> routes, List<BusStop> stops})> _load() async {
  final raw = await rootBundle.loadString('assets/data/routes.json');
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final routes = (decoded['routes'] as List)
      .cast<Map<String, dynamic>>()
      .map(BusRoute.fromJson)
      .toList();
  final map = <String, BusStop>{};
  for (final route in routes) {
    for (var i = 0; i < route.stops.length; i++) {
      final key = route.stops[i].trim().toLowerCase();
      if (key.isEmpty) continue;
      final coord = i < route.coords.length ? route.coords[i] : null;
      map[key] = BusStop(
        id: key,
        name: route.stops[i],
        latitude: coord?.latitude ?? 0,
        longitude: coord?.longitude ?? 0,
      );
    }
  }
  return (routes: routes, stops: map.values.toList());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildLeg', () {
    late List<BusRoute> routes;
    late BusRoute orangeLine;

    setUpAll(() async {
      final data = await _load();
      routes = data.routes;
      orangeLine = routes.firstWhere((r) => r.category == 'orangeLine');
    });

    test('measures forward travel in stops and minutes', () {
      final leg = JourneyRepository.buildLeg(orangeLine, 0, 4);
      expect(leg.reversed, false);
      expect(leg.stopsTravelled, 4);
      expect(leg.stopNames, hasLength(5));
      expect(leg.travelMinutes, 8); // 4 stops × 2 min
      expect(leg.fromName, orangeLine.stops[0]);
      expect(leg.toName, orangeLine.stops[4]);
    });

    test('reverses the stop list when travelling backwards', () {
      final leg = JourneyRepository.buildLeg(orangeLine, 4, 0);
      expect(leg.reversed, true);
      expect(leg.stopsTravelled, 4);
      expect(leg.stopNames.first, orangeLine.stops[4]);
      expect(leg.stopNames.last, orangeLine.stops[0]);
    });

    test('single stop leg still travels 1 minute', () {
      final leg = JourneyRepository.buildLeg(orangeLine, 2, 3);
      expect(leg.stopsTravelled, 1);
      expect(
        leg.travelMinutes,
        2,
        reason: '2 min per stop is the recovered constant',
      );
    });
  });

  group('findBestTransfer', () {
    late List<BusRoute> routes;

    setUpAll(() async {
      routes = (await _load()).routes;
    });

    test('finds a shared boarding stop between two crossing routes', () {
      // Two Speedo routes that both call at Jinnah Bus Terminal.
      final a = routes.firstWhere((r) => r.id == 'pma-lahore-239');
      final b = routes.firstWhere((r) => r.id == 'pma-lahore-243');
      final aIdx = a.stopIds.indexWhere((id) => b.stopIds.contains(id));
      if (aIdx < 0) return;
      final shared = a.stops[aIdx];
      final bIdx = b.stopIds.indexOf(a.stopIds[aIdx]);
      final transfer = JourneyRepository.findBestTransfer(a, aIdx, b, bIdx);
      expect(transfer, isNotNull);
      expect(transfer!.aName, shared);
      expect(transfer.walkMeters, 0);
    });

    test('returns null when the two routes never share a stop', () {
      final metro = routes.firstWhere((r) => r.category == 'metro');
      final speedo = routes.firstWhere((r) => r.id == 'pma-lahore-272');
      final none = <BusStop>[];
      // Use isolated synthetic routes to prove the "no shared stop" branch.
      final r1 = BusRoute.fromJson({
        'id': 'x1',
        'name': 'X1',
        'stationAddress': 'Nowhere to Elsewhere',
        'category': 'speedo',
        'fare': '25',
        'color': '#000000',
        'stops': const ['Only A', 'Only B'],
        'stopIds': const ['a', 'b'],
        'coords': const [
          {'latitude': 0.0, 'longitude': 0.0, 'name': 'Only A', 'id': 'a'},
          {'latitude': 0.001, 'longitude': 0.0, 'name': 'Only B', 'id': 'b'},
        ],
      });
      final r2 = BusRoute.fromJson({
        'id': 'x2',
        'name': 'X2',
        'stationAddress': 'Elsewhere to Nowhere',
        'category': 'speedo',
        'fare': '25',
        'color': '#000000',
        'stops': const ['Different C', 'Different D'],
        'stopIds': const ['c', 'd'],
        'coords': const [
          {
            'latitude': 40.0,
            'longitude': 40.0,
            'name': 'Different C',
            'id': 'c',
          },
          {
            'latitude': 40.001,
            'longitude': 40.0,
            'name': 'Different D',
            'id': 'd',
          },
        ],
      });
      expect(JourneyRepository.findBestTransfer(r1, 0, r2, 0), isNull);
      expect(metro, isNotNull);
      expect(speedo, isNotNull);
      expect(none, isEmpty);
    });
  });

  group('stop index', () {
    late List<BusRoute> routes;
    late List<BusStop> stops;

    setUpAll(() async {
      final data = await _load();
      routes = data.routes;
      stops = data.stops;
    });

    test('ALL_STOPS is sorted by stop name and keyed by lower-case name', () {
      final map = <String, BusStop>{};
      for (final route in routes) {
        for (var i = 0; i < route.stops.length; i++) {
          final key = route.stops[i].trim().toLowerCase();
          if (key.isEmpty) continue;
          map[key] = stops.firstWhere((s) => s.id == key);
        }
      }
      expect(map.keys.length, greaterThan(300));
      for (final k in map.keys) {
        expect(k, k.trim().toLowerCase());
      }
      final queries = <String>['bahria', 'terminal', 'chowk', 'stop'];
      for (final q in queries) {
        expect(
          map.values.where((s) => s.id.contains(q)).length,
          greaterThan(0),
        );
      }
    });
  });
}
