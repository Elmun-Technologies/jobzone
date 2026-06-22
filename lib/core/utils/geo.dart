import 'package:latlong2/latlong.dart';

/// Great-circle distance in kilometers between two coordinates, or null when
/// either point is missing. Uses [latlong2]'s `Distance` (already a dependency)
/// rather than a hand-rolled haversine.
double? geoDistanceKm(double? aLat, double? aLng, double? bLat, double? bLng) {
  if (aLat == null || aLng == null || bLat == null || bLng == null) return null;
  return const Distance().as(
    LengthUnit.Kilometer,
    LatLng(aLat, aLng),
    LatLng(bLat, bLng),
  );
}

/// Display-ready distance: `"750 m"` under 1 km, otherwise `"5.2 km"`.
String formatKm(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(1)} km';
}
