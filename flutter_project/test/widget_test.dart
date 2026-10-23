import 'package:flutter_test/flutter_test.dart';
import 'package:lahore_speedo_bus_guide/app/router.dart';
import 'package:lahore_speedo_bus_guide/data/models/bus_stop.dart';
import 'package:lahore_speedo_bus_guide/data/models/coord.dart';
import 'package:lahore_speedo_bus_guide/data/models/route.dart';
import 'package:lahore_speedo_bus_guide/data/repositories/departures.dart';

void main() {
  group('route model', () {
    test('parses the recovered GTFS shape', () {
      final route = BusRoute.fromJson(const {
        'id': 'pma-lahore-59',
        'name': 'Electric RT20',
        'stationAddress': 'Jinnah Bus Terminal to Raiwind',
        'frequency': 'Every 10-30 minutes',
        'operatingHours': '06:00 AM - 10:00 PM',
        'category': 'electric',
        'fare': '25',
        'color': '#D6298E',
        'textColor': '#FFFFFF',
        'stops': ['A', 'B', 'C'],
        'stopIds': ['a', 'b', 'c'],
        'coords': [
          {'latitude': 31.2, 'longitude': 74.2, 'name': 'A', 'id': 'a'},
          {'latitude': 31.3, 'longitude': 74.2, 'name': 'B', 'id': 'b'},
          {'latitude': 31.4, 'longitude': 74.2, 'name': 'C', 'id': 'c'},
        ],
      });

      expect(route.id, 'pma-lahore-59');
      expect(route.fareValue, 25);
      expect(route.stops, ['A', 'B', 'C']);
      expect(route.coords.first.coordTypeName, 'Coord');
      expect(route.toJson()['fare'], '25');
    });
  });

  group('Coord', () {
    test('round-trips', () {
      const c = Coord(latitude: 1.5, longitude: 2.5, name: 'X', id: 'x');
      expect(Coord.fromJson(c.toJson()).latitude, 1.5);
    });
  });

  group('departures', () {
    test('timeToMinutes handles AM/PM and midnight', () {
      expect(Departures.timeToMinutes('6:00 AM'), 360);
      expect(Departures.timeToMinutes('10:00 PM'), 1320);
      expect(Departures.timeToMinutes('12:00 AM'), 0);
      expect(Departures.timeToMinutes('12:30 PM'), 750);
      expect(Departures.timeToMinutes(null), null);
    });

    test('parseOperatingHours defaults and splits', () {
      expect(Departures.parseOperatingHours(null).start, 360);
      expect(Departures.parseOperatingHours(null).end, 1320);
      final h = Departures.parseOperatingHours('06:00 AM - 10:00 PM');
      expect(h.start, 360);
      expect(h.end, 1320);
    });

    test('parseFrequencyMinutes averages first and last', () {
      expect(Departures.parseFrequencyMinutes('Every 10-30 minutes'), 20);
      expect(Departures.parseFrequencyMinutes('Every 10-20 minutes'), 15);
      expect(Departures.parseFrequencyMinutes('Every 25 minutes'), 25);
      expect(Departures.parseFrequencyMinutes(null), 15);
    });

    test('formatClock', () {
      expect(Departures.formatClock(360), '6:00 AM');
      expect(Departures.formatClock(1320), '10:00 PM');
      expect(Departures.formatClock(0), '12:00 AM');
      expect(Departures.formatClock(725), '12:05 PM');
    });

    test('formatDeparture', () {
      expect(Departures.formatDeparture(360, 0), 'Due');
      expect(Departures.formatDeparture(360, 25), '25 min');
      expect(Departures.formatDeparture(360, 90), '6:00 AM');
    });

    test('getNextDepartures produces 5 departures inside hours', () {
      final out = Departures.getNextDepartures(
        'Every 10-20 minutes',
        '06:00 AM - 10:00 PM',
        now: DateTime(2024, 1, 1, 9, 0),
      );
      expect(out.length, 5);
      expect(out.first.minutesAway, 0);
      expect(out.first.display, 'Due');
    });

    test('getNextDepartures is empty after the last bus', () {
      final out = Departures.getNextDepartures(
        'Every 15 minutes',
        '06:00 AM - 10:00 PM',
        now: DateTime(2024, 1, 1, 23, 0),
      );
      expect(out, isEmpty);
    });

    test('formatMinutes / formatWalkDistance', () {
      expect(Departures.formatMinutes(45), '45 min');
      expect(Departures.formatMinutes(75), '1h 15m');
      expect(Departures.formatMinutes(120), '2h');
      expect(Departures.formatWalkDistance(350), '350 m');
      expect(Departures.formatWalkDistance(1200), '1.2 km');
      expect(Departures.walkMinutesFor(40), 1);
      expect(Departures.walkMinutesFor(160), 2);
    });
  });

  group('router routes', () {
    test('route names match the original stack navigator', () {
      expect(Routes.mainTabs, 'MainTabs');
      expect(Routes.search, 'Search');
      expect(Routes.routeDetail, 'RouteDetail');
      expect(Routes.stopDetail, 'StopDetail');
      expect(Routes.map, 'Map');
      expect(Routes.stopPicker, 'StopPicker');
      expect(Routes.journeyResults, 'JourneyResults');
      expect(Routes.journeyDetail, 'JourneyDetail');
      expect(Routes.credits, 'Credits');
      expect(Routes.feedback, 'Feedback');
    });

    test('argument records carry the original route params', () {
      const a = StopPickerArgs(mode: 'from', title: 'Select Departure Stop');
      expect(a.mode, 'from');
      const b = JourneyResultsArgs(
        fromKey: 'a',
        toKey: 'b',
        fromName: 'A',
        toName: 'B',
      );
      expect(b.fromName, 'A');
      final c = const StopPickerResult(
        BusStop(id: 'a', name: 'A', latitude: 0, longitude: 0),
      );
      expect(c.stop.name, 'A');
    });
  });
}

extension _CoordName on Object {
  String get coordTypeName => runtimeType.toString();
}
