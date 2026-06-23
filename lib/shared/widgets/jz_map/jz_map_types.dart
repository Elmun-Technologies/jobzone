import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

/// Marker kind → pin colour/icon. Keeps call-sites free of platform details.
enum JzMarkerKind { job, applicant, picked }

/// A pin on a [JzMapView]. Uses the app-wide `latlong2` [LatLng]; the platform
/// implementations convert to their native point type.
class JzMapMarker {
  const JzMapMarker({
    required this.id,
    required this.point,
    this.kind = JzMarkerKind.job,
    this.label,
    this.onTap,
  });

  /// Stable id (used as the Yandex `MapObjectId`).
  final String id;
  final LatLng point;
  final JzMarkerKind kind;

  /// Optional short text shown on the marker (e.g. a salary). Mobile renders it
  /// into the pin bitmap as a pill; web shows it as a pill widget. Null → a
  /// plain pin.
  final String? label;
  final VoidCallback? onTap;
}

/// Imperative handle to recenter the map (e.g. a "my location" button). Bound by
/// whichever [JzMapView] implementation is active; calls before binding no-op.
class JzMapController {
  void Function(LatLng point, double zoom)? _move;

  void moveTo(LatLng point, {double zoom = 13}) => _move?.call(point, zoom);

  // ignore: use_setters_to_change_properties
  void bind(void Function(LatLng, double) move) => _move = move;
  void unbind() => _move = null;
}
