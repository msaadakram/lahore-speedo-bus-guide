library;

/// Normalised route model — the exact shape produced by the original app's
/// `routes.ts` (Metro module 718) over the embedded GTFS (`gtfsData`, 719).
///
///   {
///     id, name, stationAddress, frequency, operatingHours, category, fare,
///     color, stops: [name], stopIds: [id], coords: [{latitude, longitude, name, id}]
///   }
import 'coord.dart';

class BusRoute {
  const BusRoute({
    required this.id,
    required this.name,
    required this.stationAddress,
    required this.frequency,
    required this.operatingHours,
    required this.category,
    required this.fare,
    required this.color,
    required this.textColor,
    this.agency,
    this.schedule,
    required this.patterns,
    required this.stops,
    required this.stopIds,
    required this.coords,
  });

  final String id;
  final String name;
  final String stationAddress;
  final String? frequency;
  final String? operatingHours;
  final String category;
  final String fare;
  final String color;
  final String textColor;
  final String? agency;
  final RouteSchedule? schedule;
  final List<RoutePattern> patterns;
  final List<String> stops;
  final List<String> stopIds;
  final List<Coord> coords;

  int get fareValue => int.tryParse(fare) ?? 0;

  Coord? get firstCoord => coords.isEmpty ? null : coords.first;

  Coord? get lastCoord => coords.isEmpty ? null : coords.last;

  bool containsStop(String stopId) => stopIds.contains(stopId);

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      id: json['id'] as String,
      name: json['name'] as String,
      stationAddress: (json['stationAddress'] ?? '') as String,
      frequency: json['frequency'] as String?,
      operatingHours: json['operatingHours'] as String?,
      category: (json['category'] ?? '') as String,
      fare: (json['fare'] ?? '25') as String,
      color: (json['color'] ?? '#000000') as String,
      textColor: (json['textColor'] ?? '#FFFFFF') as String,
      agency: json['agency'] as String?,
      schedule: json['schedule'] == null
          ? null
          : RouteSchedule.fromJson(json['schedule'] as Map<String, dynamic>),
      patterns: (json['patterns'] as List<dynamic>? ?? const [])
          .map((e) => RoutePattern.fromJson(e as Map<String, dynamic>))
          .toList(),
      stops: (json['stops'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      stopIds: (json['stopIds'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      coords: (json['coords'] as List<dynamic>? ?? const [])
          .map((e) => Coord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'stationAddress': stationAddress,
    'frequency': frequency,
    'operatingHours': operatingHours,
    'category': category,
    'fare': fare,
    'color': color,
    'textColor': textColor,
    'agency': agency,
    'schedule': schedule?.toJson(),
    'patterns': patterns.map((e) => e.toJson()).toList(),
    'stops': stops,
    'stopIds': stopIds,
    'coords': coords.map((e) => e.toJson()).toList(),
  };
}

/// `{ first: '06:00 AM', last: '10:00 PM' }`
class RouteSchedule {
  const RouteSchedule({required this.first, required this.last});

  final String first;
  final String last;

  factory RouteSchedule.fromJson(Map<String, dynamic> json) => RouteSchedule(
    first: json['first'] as String,
    last: json['last'] as String,
  );

  Map<String, dynamic> toJson() => {'first': first, 'last': last};
}

/// GTFS `pattern` record.
class RoutePattern {
  const RoutePattern({
    required this.id,
    required this.headsign,
    required this.direction,
  });

  final String id;
  final String headsign;
  final int direction;

  factory RoutePattern.fromJson(Map<String, dynamic> json) => RoutePattern(
    id: (json['id'] ?? '') as String,
    headsign: (json['headsign'] ?? '') as String,
    direction: (json['direction'] ?? 1) as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'headsign': headsign,
    'direction': direction,
  };
}
