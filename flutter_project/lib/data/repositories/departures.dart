/// Departure-time logic recovered from the original app
/// (`schedule.ts`, Metro module 735).
///
/// All functions are pure so they can be unit-tested with an injected "now".
library;

class Departures {
  const Departures._();

  /// `timeToMinutes('6:00 AM')` → minutes since midnight, or `null`.
  static int? timeToMinutes(String? value) {
    if (value == null) return null;
    final m = RegExp(
      r'(\d{1,2}):(\d{2})\s*(AM|PM)',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (m == null) return null;
    var hour = int.parse(m.group(1)!);
    final minute = int.parse(m.group(2)!);
    final ampm = m.group(3)!.toUpperCase();
    if (ampm == 'PM' && hour != 12) hour += 12;
    if (ampm == 'AM' && hour == 12) hour = 0;
    return hour * 60 + minute;
  }

  /// `parseOperatingHours()` → `{start, end}`; defaults `6:00 AM - 10:00 PM`.
  static ({int start, int end}) parseOperatingHours(String? value) {
    final raw = (value == null || value.isEmpty) ? '6:00 AM - 10:00 PM' : value;
    final parts = raw.split(RegExp(r'-|to', caseSensitive: false));
    final a = parts.isNotEmpty ? timeToMinutes(parts[0]) : null;
    final b = parts.length > 1 ? timeToMinutes(parts[1]) : null;
    return (start: a ?? 0, end: b ?? 1439);
  }

  /// `parseFrequencyMinutes()` — averages the first and last number found.
  /// Defaults to 15.
  static int parseFrequencyMinutes(String? value) {
    final raw = (value == null || value.isEmpty) ? '15' : value;
    final nums = RegExp(r'\d+')
        .allMatches(raw)
        .map((m) => int.parse(m.group(0)!))
        .toList();
    if (nums.isEmpty) return 15;
    final first = nums.first;
    final last = nums.length > 1 ? nums.last : nums.first;
    return ((first + last) / 2).round();
  }

  /// `formatClock(minutesOfDay)` → `h:mm AM/PM`.
  static String formatClock(int minutesOfDay) {
    final h = (minutesOfDay ~/ 60) % 24;
    final m = minutesOfDay % 60;
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final mm = m.toString().padLeft(2, '0');
    return '$h12:$mm $ampm';
  }

  /// `formatDeparture(timeOfDay, minutesAway)`.
  static String formatDeparture(int timeOfDay, int minutesAway) {
    if (minutesAway <= 0) return 'Due';
    if (minutesAway < 60) return '$minutesAway min';
    return formatClock(timeOfDay);
  }

  /// `getNextDepartures(frequency, operatingHours, limit = 5, now)`.
  static List<Departure> getNextDepartures(
    String? frequency,
    String? operatingHours, {
    int limit = 5,
    DateTime? now,
  }) {
    final freq = parseFrequencyMinutes(frequency);
    final hours = parseOperatingHours(operatingHours);
    final clock = now ?? DateTime.now();
    final nowMinutes = clock.hour * 60 + clock.minute;
    if (nowMinutes > hours.end) return const [];

    var next = nowMinutes < hours.start
        ? hours.start
        : hours.start + ((nowMinutes - hours.start) / freq).ceil() * freq;

    final out = <Departure>[];
    while (next <= hours.end && out.length < limit) {
      final minutesAway = next - nowMinutes < 0 ? 0 : next - nowMinutes;
      out.add(
        Departure(
          display: formatDeparture(next, minutesAway),
          minutesAway: minutesAway,
          timeOfDay: next,
        ),
      );
      next += freq;
    }
    return out;
  }

  /// `formatMinutes(m)` → `45 min` / `1h 20m`.
  static String formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  /// `formatWalkDistance(m)` → `350 m` / `1.2 km`.
  static String formatWalkDistance(int meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  /// Walk time for a distance. 80 m/min ≈ 4.8 km/h.
  static int walkMinutesFor(int meters) {
    final v = meters / 80;
    return v < 1 ? 1 : v.round();
  }
}

class Departure {
  const Departure({
    required this.display,
    required this.minutesAway,
    required this.timeOfDay,
  });

  final String display;
  final int minutesAway;
  final int timeOfDay;
}
