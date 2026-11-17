/// Utility class for formatting distance values
class DistanceFormatter {
  /// Format distance in meters to a human-readable string
  /// - If distance >= 1000 meters, show in kilometers (e.g., "2.78 km")
  /// - If distance < 1000 meters, show in meters (e.g., "500 m")
  static String format(double distanceInMeters, {int decimals = 1}) {
    if (distanceInMeters >= 1000) {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(decimals)} km';
    } else {
      return '${distanceInMeters.toStringAsFixed(decimals)} m';
    }
  }

  /// Format distance with full unit name
  /// - If distance >= 1000 meters, show in kilometers (e.g., "2.78 kilometers")
  /// - If distance < 1000 meters, show in meters (e.g., "500 meters")
  static String formatLong(double distanceInMeters, {int decimals = 1}) {
    if (distanceInMeters >= 1000) {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(decimals)} kilometers';
    } else {
      return '${distanceInMeters.toStringAsFixed(decimals)} meters';
    }
  }

  /// Get just the numeric value as string
  static String formatValue(double distanceInMeters, {int decimals = 1}) {
    if (distanceInMeters >= 1000) {
      final km = distanceInMeters / 1000;
      return km.toStringAsFixed(decimals);
    } else {
      return distanceInMeters.toStringAsFixed(decimals);
    }
  }

  /// Get just the unit
  static String getUnit(double distanceInMeters) {
    return distanceInMeters >= 1000 ? 'km' : 'm';
  }

  /// Get full unit name
  static String getUnitLong(double distanceInMeters) {
    return distanceInMeters >= 1000 ? 'kilometers' : 'meters';
  }
}
