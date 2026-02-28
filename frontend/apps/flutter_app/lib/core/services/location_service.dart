import 'package:geolocator/geolocator.dart';

class Coordinates {
  const Coordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  String format() =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}

enum LocationFailureType {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  unknown,
}

class LocationException implements Exception {
  const LocationException(this.type, this.message);

  final LocationFailureType type;
  final String message;

  @override
  String toString() => message;
}

class LocationService {
  Future<Coordinates> getCurrentCoordinates() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        LocationFailureType.servicesDisabled,
        'Location services are disabled. Enable GPS/location and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationException(
        LocationFailureType.permissionDenied,
        'Location permission denied.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        LocationFailureType.permissionDeniedForever,
        'Location permission is permanently denied. Update it in system settings.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return Coordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      throw const LocationException(
        LocationFailureType.unknown,
        'Unable to fetch current coordinates.',
      );
    }
  }
}
