/// `{ latitude, longitude, name, id }` — the coordinate shape used by the
/// original app for stop positions on the map.
class Coord {
  const Coord({
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.id,
  });

  final double latitude;
  final double longitude;
  final String name;
  final String id;

  factory Coord.fromJson(Map<String, dynamic> json) => Coord(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    name: (json['name'] ?? '') as String,
    id: (json['id'] ?? '') as String,
  );

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'name': name,
    'id': id,
  };
}
