import 'package:geolocator/geolocator.dart';

/// A captured geo-tag: where the user was at a specific moment.
class LocationResult {
  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime timestamp;

  /// `-26.20227, 28.04363` — rounded for display.
  String get coordinatesLabel =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy_m': accuracyMeters,
    'timestamp': timestamp.toIso8601String(),
  };
}

class LocationException implements Exception {
  const LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Wraps the geolocator plugin behind a single call that handles the
/// service/permission dance and returns a [LocationResult] or throws a
/// [LocationException] with a user-friendly message.
class LocationService {
  const LocationService();

  Future<LocationResult> getCurrentLocation() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        'Location services are turned off. Please enable them in Settings.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(
        'Location permission was declined. MoTiroong needs your location to verify sign-ins.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location permission is blocked. Allow location access for MoTiroong in Settings.',
      );
    }

    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      timestamp: position.timestamp,
    );
  }
}
