import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Common radius for manifestations
  static const double defaultRadiusMeters = 1500.0;

  /// Explicitly request location permission
  Future<PermissionStatus> requestLocationPermission() async {
    return await Permission.location.request();
  }

  /// Check current permission status
  Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Check if location services (GPS) are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Check permissions and get current position with iterative accuracy fallback
  Future<Position?> getCurrentPosition() async {
    final status = await Permission.location.status;
    if (!status.isGranted) return null;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    // Try Medium/High Accuracy with a shorter timeout
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 7),
        ),
      );
    } catch (_) {
      // Fallback: Try last known position as a last resort
      return await Geolocator.getLastKnownPosition();
    }
  }

  /// Check if a position is within the geofence of a specific target
  bool isWithinGeofence(
      double userLat, double userLon, double targetLat, double targetLon,
      {double radius = defaultRadiusMeters}) {
    final distance = Geolocator.distanceBetween(
      userLat,
      userLon,
      targetLat,
      targetLon,
    );
    return distance <= radius;
  }
}
