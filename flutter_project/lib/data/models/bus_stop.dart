/// A unique bus stop derived from the embedded GTFS coordinates.
///
/// The original app builds stop objects on demand from `BusRoute.coords`
/// (helpers `getStopByKey` / `searchStops` / `routeById`, Metro module 734).
class BusStop {
  const BusStop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.routes = const [],
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final List<String> routes;

  factory BusStop.fromJson(Map<String, dynamic> json) => BusStop(
    id: (json['id'] ?? '') as String,
    name: (json['name'] ?? '') as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    routes: (json['routes'] as List<dynamic>? ?? const [])
        .map((e) => e as String)
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'routes': routes,
  };

  BusStop copyWith({List<String>? routes}) => BusStop(
    id: id,
    name: name,
    latitude: latitude,
    longitude: longitude,
    routes: routes ?? this.routes,
  );
}
