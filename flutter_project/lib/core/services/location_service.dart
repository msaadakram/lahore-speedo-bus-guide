import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Wraps `geolocator` with the same behaviour as the original
/// `react-native-geolocation-service` wrapper (Metro module 729) plus the
/// permission helper (module 1491).
class LocationService {
  const LocationService._();

  static const int timeoutMs = 15000;

  Future<bool> requestPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<bool> get isLocationServiceEnabled =>
      Geolocator.isLocationServiceEnabled();

  /// Returns `null` when the position cannot be determined.
  Future<Position?> currentLocation() async {
    try {
      final ok = await requestPermission();
      if (!ok) return null;
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(milliseconds: timeoutMs),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}

final locationServiceProvider = Provider<LocationService>(
  (_) => const LocationService._(),
);
