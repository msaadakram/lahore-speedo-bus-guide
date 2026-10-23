import 'route.dart';

/// `CATEGORIES` / `CATEGORIES_FOR_SEARCH` — Metro module 715.
///
///   { key, label, color, icon, data: BusRoute[] }
class RouteCategory {
  const RouteCategory({
    required this.key,
    required this.label,
    required this.color,
    required this.data,
    this.icon,
  });

  final String key;
  final String label;
  final String color;
  final String? icon;
  final List<BusRoute> data;

  factory RouteCategory.fromJson(Map<String, dynamic> json) {
    return RouteCategory(
      key: (json['key'] ?? '') as String,
      label: (json['label'] ?? '') as String,
      color: (json['color'] ?? '#fc3b38') as String,
      icon: json['icon'] as String?,
      data: (json['data'] as List<dynamic>? ?? const [])
          .map((e) => BusRoute.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'color': color,
    'icon': icon,
    'data': data.map((e) => e.toJson()).toList(),
  };
}
