import 'package:geolocator/geolocator.dart';

/// Why the phone's location couldn't be read, in words fit for a snackbar.
class LocationException implements Exception {
  final String message;

  /// True when the fix is to allow location in the app's settings.
  final bool canOpenSettings;

  const LocationException(this.message, {this.canOpenSettings = false});

  @override
  String toString() => message;
}

class DeviceLocationService {
  /// The phone's current position. Asks for permission if needed; throws a
  /// [LocationException] if location is off, denied, or can't be read.
  static Future<Position> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException('Turn on location (GPS) on your phone.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location permission is blocked. Allow it in app settings.',
        canOpenSettings: true,
      );
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(
        'Location permission is needed to use your current location.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      throw const LocationException(
        "Couldn't get your location. Try again outdoors.",
      );
    }
  }
}
