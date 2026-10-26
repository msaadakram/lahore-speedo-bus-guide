import '../models/route.dart';
import 'departures.dart';
import 'routes_repository.dart';
import 'stop_repository.dart';

/// One bus leg of a journey. Mirrors the object produced by the original
/// `buildLeg` helper (Metro module 734).
class Leg {
  const Leg({
    required this.routeId,
    required this.routeName,
    required this.category,
    required this.color,
    required this.fare,
    required this.frequency,
    required this.operatingHours,
    required this.fromName,
    required this.toName,
    required this.reversed,
    required this.stopsTravelled,
    required this.stopNames,
    required this.travelMinutes,
    this.departureTime,
    this.arrivalTime,
    this.departureClock,
    this.arrivalClock,
    this.waitMinutes = 0,
  });

  final String routeId;
  final String routeName;
  final String category;
  final String color;
  final String fare;
  final String? frequency;
  final String? operatingHours;
  final String fromName;
  final String toName;
  final bool reversed;
  final int stopsTravelled;
  final List<String> stopNames;
  final int travelMinutes;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final String? departureClock;
  final String? arrivalClock;
  final int waitMinutes;
}

class Transfer {
  const Transfer({
    required this.fromName,
    required this.toName,
    required this.walkMeters,
  });

  final String fromName;
  final String toName;
  final int walkMeters;
}

class Journey {
  const Journey({
    required this.legs,
    required this.transfers,
    this.transferWalk,
    required this.totalStops,
    required this.totalFare,
    required this.totalWalkMinutes,
    required this.estimatedMinutes,
    required this.startTime,
    required this.arrivalTime,
    required this.startClock,
    required this.arrivalClock,
  });

  final List<Leg> legs;
  final int transfers;
  final Transfer? transferWalk;
  final int totalStops;
  final int totalFare;
  final int totalWalkMinutes;
  final int estimatedMinutes;
  final DateTime startTime;
  final DateTime arrivalTime;
  final String startClock;
  final String arrivalClock;
}

/// Journey planner rebuilt from the original `findJourneys` /
/// `findBestTransfer` (Metro module 734).
///
/// Behaviour:
/// * direct journeys = one leg on a route that serves both stops;
/// * one-transfer journeys = two different routes with a shared boarding stop,
///   optionally bridged by a short walk (< 600 m) between nearby stops;
/// * up to 8 results, direct first, then by total stops travelled.
class JourneyRepository {
  const JourneyRepository._();

  static const int walkRadiusMeters = 600;
  static const int kTransferPenaltyMinutes = 80;
  static const int kConnectionBufferMinutes = 5;

  static Leg buildLeg(BusRoute route, int fromIndex, int toIndex) {
    final reversed = fromIndex > toIndex;
    final lo = mathMin(fromIndex, toIndex);
    final hi = mathMax(fromIndex, toIndex);
    final stopsTravelled = hi - lo;
    final names = route.stops.sublist(lo, hi + 1);
    return Leg(
      routeId: route.id,
      routeName: route.name,
      category: route.category,
      color: route.color,
      fare: route.fare,
      frequency: route.frequency,
      operatingHours: route.operatingHours,
      fromName: route.stops[fromIndex],
      toName: route.stops[toIndex],
      reversed: reversed,
      stopsTravelled: stopsTravelled,
      stopNames: reversed ? names.reversed.toList() : names,
      travelMinutes: mathMax(1, (stopsTravelled * 2).round()),
    );
  }

  /// Finds the cheapest boarding stop pair between two routes.
  static ({
    int aIdx,
    int bIdx,
    String aName,
    String bName,
    int walkMeters,
    int cost,
  })?
  findBestTransfer(BusRoute routeA, int aIdx, BusRoute routeB, int bIdx) {
    final bIndex = <String, int>{};
    for (var i = 0; i < routeB.stops.length; i++) {
      final k = norm(routeB.stops[i]);
      if (k.isNotEmpty) bIndex.putIfAbsent(k, () => i);
    }

    ({
      int aIdx,
      int bIdx,
      String aName,
      String bName,
      int walkMeters,
      int cost,
    })?
    best;
    for (var aI = 0; aI < routeA.stops.length; aI++) {
      final key = norm(routeA.stops[aI]);
      if (key.isEmpty) continue;
      final bI = bIndex[key];
      if (bI == null || aI == aIdx || bI == bIdx) continue;
      final cost = (aI - aIdx).abs() + (bI - bIdx).abs();
      if (best != null && best.cost <= cost) continue;
      best = (
        aIdx: aI,
        bIdx: bI,
        aName: routeA.stops[aI],
        bName: routeB.stops[bI],
        walkMeters: 0,
        cost: cost,
      );
    }

    // Allow a short walk between two different-but-nearby stops. The walk must
    // start from a real alighting stop on route A; anchoring it at the origin
    // used to create a phantom "origin → origin" bus leg and charge a second
    // fare for a walk-only connection.
    for (var aI = 0; aI < routeA.stops.length; aI++) {
      if (aI == aIdx) continue;
      final stopA = StopRepository.instance.byKey(norm(routeA.stops[aI]));
      if (stopA == null || stopA.latitude == 0 || stopA.longitude == 0) {
        continue;
      }
      final nearby = StopRepository.instance.nearby(
        latitude: stopA.latitude,
        longitude: stopA.longitude,
        radiusMeters: walkRadiusMeters,
      );
      for (final near in nearby.take(12)) {
        for (var bI = 0; bI < routeB.stops.length; bI++) {
          if (bI == bIdx || norm(routeB.stops[bI]) != near.stop.id) continue;
          final walk = near.distanceMeters;
          final cost =
              (aI - aIdx).abs() +
              (bI - bIdx).abs() +
              (walk / kTransferPenaltyMinutes).round();
          if (best != null && best.cost <= cost) continue;
          best = (
            aIdx: aI,
            bIdx: bI,
            aName: routeA.stops[aI],
            bName: routeB.stops[bI],
            walkMeters: walk,
            cost: cost,
          );
        }
      }
    }
    return best;
  }

  static String norm(String value) => value.trim().toLowerCase();

  /// `findJourneys(fromKey, toKey, limit = 8, now)`.
  static List<Journey> findJourneys(
    String fromKey,
    String toKey, {
    int limit = 8,
    DateTime? now,
  }) {
    if (fromKey.isEmpty || toKey.isEmpty || fromKey == toKey) return const [];
    final from = StopRepository.instance.byKey(fromKey);
    final to = StopRepository.instance.byKey(toKey);
    if (from == null || to == null) return const [];
    final routes = RoutesRepository.instance;
    final clock = now ?? DateTime.now();

    final found = <({List<Leg> legs, int transfers, Transfer? walk})>[];

    // ---- direct -----------------------------------------------------------
    for (final a in StopRepository.instance.routesFor(fromKey)) {
      for (final b in StopRepository.instance.routesFor(toKey)) {
        if (a.routeId != b.routeId) continue;
        final route = routes.routeById(a.routeId);
        if (route == null) continue;
        found.add((
          legs: [buildLeg(route, a.index, b.index)],
          transfers: 0,
          walk: null,
        ));
      }
    }

    // ---- one transfer ------------------------------------------------------
    for (final a in StopRepository.instance.routesFor(fromKey)) {
      final routeA = routes.routeById(a.routeId);
      if (routeA == null) continue;
      for (final b in StopRepository.instance.routesFor(toKey)) {
        if (b.routeId == a.routeId) continue;
        final routeB = routes.routeById(b.routeId);
        if (routeB == null) continue;
        final transfer = findBestTransfer(routeA, a.index, routeB, b.index);
        if (transfer == null) continue;
        found.add((
          legs: [
            buildLeg(routeA, a.index, transfer.aIdx),
            buildLeg(routeB, transfer.bIdx, b.index),
          ],
          transfers: 1,
          walk: Transfer(
            fromName: transfer.aName,
            toName: transfer.bName,
            walkMeters: transfer.walkMeters,
          ),
        ));
      }
    }

    found.sort((x, y) {
      if (x.transfers != y.transfers) return x.transfers.compareTo(y.transfers);
      final sx = x.legs.fold<int>(0, (a, l) => a + l.stopsTravelled);
      final sy = y.legs.fold<int>(0, (a, l) => a + l.stopsTravelled);
      return sx.compareTo(sy);
    });

    final out = <Journey>[];
    for (final entry in found) {
      if (out.length >= limit) break;
      out.add(_finalise(entry.legs, entry.transfers, entry.walk, clock));
    }
    return out;
  }

  static Journey _finalise(
    List<Leg> rawLegs,
    int transfers,
    Transfer? transferWalk,
    DateTime start,
  ) {
    var time = start;
    var totalWalkMeters = 0;
    final legs = <Leg>[];

    for (var i = 0; i < rawLegs.length; i++) {
      final leg = rawLegs[i];
      if (i == 0) {
        final wait = _waitMinutes(time, leg);
        time = time.add(Duration(minutes: wait));
      } else {
        if (transferWalk != null && transferWalk.walkMeters > 0) {
          totalWalkMeters += transferWalk.walkMeters;
          time = time.add(
            Duration(minutes: walkMinutesFor(transferWalk.walkMeters)),
          );
        }
        // Connections are never instantaneous: allow at least a short buffer,
        // or the next scheduled departure of the connecting line if that is
        // later.
        final connectionWait = _waitMinutes(time, leg);
        time = time.add(
          Duration(minutes: mathMax(kConnectionBufferMinutes, connectionWait)),
        );
      }
      final departure = time;
      final arrival = departure.add(Duration(minutes: leg.travelMinutes));
      legs.add(
        Leg(
          routeId: leg.routeId,
          routeName: leg.routeName,
          category: leg.category,
          color: leg.color,
          fare: leg.fare,
          frequency: leg.frequency,
          operatingHours: leg.operatingHours,
          fromName: leg.fromName,
          toName: leg.toName,
          reversed: leg.reversed,
          stopsTravelled: leg.stopsTravelled,
          stopNames: leg.stopNames,
          travelMinutes: leg.travelMinutes,
          departureTime: departure,
          arrivalTime: arrival,
          departureClock: Departures.formatClock(
            departure.hour * 60 + departure.minute,
          ),
          arrivalClock: Departures.formatClock(
            arrival.hour * 60 + arrival.minute,
          ),
          waitMinutes: i == 0
              ? departure.difference(start).inMinutes
              : arrival.difference(start).inMinutes,
        ),
      );
      time = arrival;
    }

    final totalWalkMinutes = walkMinutesFor(totalWalkMeters);
    final totalStops = legs.fold<int>(0, (a, l) => a + l.stopsTravelled);
    final totalFare = legs.fold<int>(
      0,
      (a, l) => a + (int.tryParse(l.fare) ?? 0),
    );
    final estimated = mathMax(1, time.difference(start).inMinutes);

    return Journey(
      legs: legs,
      transfers: transfers,
      transferWalk: transferWalk,
      totalStops: totalStops,
      totalFare: totalFare,
      totalWalkMinutes: totalWalkMinutes,
      estimatedMinutes: estimated,
      startTime: start,
      arrivalTime: time,
      startClock: Departures.formatClock(start.hour * 60 + start.minute),
      arrivalClock: Departures.formatClock(time.hour * 60 + time.minute),
    );
  }

  /// `waitMinutesFrom(now, leg)` — minutes until the next departure of `leg`.
  static int _waitMinutes(DateTime now, Leg leg) {
    final hours = Departures.parseOperatingHours(leg.operatingHours);
    final freq = Departures.parseFrequencyMinutes(leg.frequency);
    final nowMin = now.hour * 60 + now.minute;
    if (nowMin > hours.end) return 0;
    if (nowMin < hours.start) return hours.start - nowMin;
    final since = nowMin - hours.start;
    final next = ((since / freq).ceil() * freq) + hours.start;
    return mathMax(0, next - nowMin);
  }
}

int mathMin(int a, int b) => a < b ? a : b;
int mathMax(int a, int b) => a > b ? a : b;
