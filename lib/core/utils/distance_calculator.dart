import 'dart:math' as math;

/// Local, offline distance calculation between two lat/lng points using the
/// Haversine formula. No maps API, no API key — only `dart:math`.

/// Mean Earth radius in kilometres (spherical approximation used by Haversine).
const double kEarthRadiusKm = 6371.0;

/// Fallback customer drop coordinates, used when an order has no real
/// shipping-address coordinates. Roughly near the demo store in Visakhapatnam
/// so the computed distance stays realistic (~5 km).
const double kSampleCustomerLatitude = 17.7180;
const double kSampleCustomerLongitude = 83.0400;

bool isValidLatitude(num? value) =>
    value != null && value.isFinite && value >= -90 && value <= 90;

bool isValidLongitude(num? value) =>
    value != null && value.isFinite && value >= -180 && value <= 180;

double _degToRad(double deg) => deg * math.pi / 180.0;

/// Great-circle distance between two coordinates, in kilometres.
///
/// - Returns `0.0` when both points are identical.
/// - Throws [ArgumentError] when a latitude is outside -90..90 or a longitude
///   is outside -180..180. Use [tryCalculateDistanceKm] for a non-throwing,
///   null-safe variant.
double calculateDistanceKm(
  double startLatitude,
  double startLongitude,
  double endLatitude,
  double endLongitude,
) {
  if (!isValidLatitude(startLatitude) || !isValidLatitude(endLatitude)) {
    throw ArgumentError('Latitude must be between -90 and 90.');
  }
  if (!isValidLongitude(startLongitude) || !isValidLongitude(endLongitude)) {
    throw ArgumentError('Longitude must be between -180 and 180.');
  }

  if (startLatitude == endLatitude && startLongitude == endLongitude) {
    return 0.0;
  }

  final dLat = _degToRad(endLatitude - startLatitude);
  final dLon = _degToRad(endLongitude - startLongitude);

  final lat1 = _degToRad(startLatitude);
  final lat2 = _degToRad(endLatitude);

  final sinDLat = math.sin(dLat / 2);
  final sinDLon = math.sin(dLon / 2);

  final a = (sinDLat * sinDLat) +
      (math.cos(lat1) * math.cos(lat2) * sinDLon * sinDLon);
  // atan2 form is numerically stable for both very small and antipodal points.
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  return kEarthRadiusKm * c;
}

/// Null-safe wrapper: returns `null` when any coordinate is missing or out of
/// range, otherwise the Haversine distance in kilometres. Never throws.
double? tryCalculateDistanceKm(
  double? startLatitude,
  double? startLongitude,
  double? endLatitude,
  double? endLongitude,
) {
  if (!isValidLatitude(startLatitude) ||
      !isValidLatitude(endLatitude) ||
      !isValidLongitude(startLongitude) ||
      !isValidLongitude(endLongitude)) {
    return null;
  }
  try {
    return calculateDistanceKm(
      startLatitude!,
      startLongitude!,
      endLatitude!,
      endLongitude!,
    );
  } catch (_) {
    return null;
  }
}
