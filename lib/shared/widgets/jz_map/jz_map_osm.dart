import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'cluster_grid.dart';
import 'jz_map_types.dart';

/// OpenStreetMap (flutter_map) implementation — used on web (where Yandex
/// MapKit has no support) and as the keyless fallback. Supports grid clustering,
/// salary-pill markers and a "me" dot, matching the Yandex implementation.
class JzMapView extends StatefulWidget {
  const JzMapView({
    super.key,
    required this.initialCenter,
    this.initialZoom = 12,
    this.markers = const [],
    this.onMapTap,
    this.controller,
    this.cluster = false,
    this.myLocation,
  });

  final LatLng initialCenter;
  final double initialZoom;
  final List<JzMapMarker> markers;
  final void Function(LatLng point)? onMapTap;
  final JzMapController? controller;

  /// When true, nearby markers collapse into count bubbles that split on zoom.
  final bool cluster;

  /// The user's current location, shown as a blue dot when set.
  final LatLng? myLocation;

  @override
  State<JzMapView> createState() => _JzMapViewState();
}

class _JzMapViewState extends State<JzMapView> {
  final _map = MapController();

  @override
  void initState() {
    super.initState();
    widget.controller?.bind((p, zoom) => _map.move(p, zoom));
  }

  @override
  void dispose() {
    widget.controller?.unbind();
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: widget.initialCenter,
        initialZoom: widget.initialZoom,
        minZoom: 3,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onTap: widget.onMapTap == null
            ? null
            : (_, point) => widget.onMapTap!(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'io.jobzone.jobzone',
        ),
        if (widget.cluster)
          _ClusterLayer(markers: widget.markers, controller: _map)
        else
          MarkerLayer(markers: [for (final m in widget.markers) _markerFor(m)]),
        if (widget.myLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: widget.myLocation!,
                width: 26,
                height: 26,
                child: const _MeDot(),
              ),
            ],
          ),
      ],
    );
  }
}

/// A single (non-clustered) job/applicant marker.
Marker _markerFor(JzMapMarker m) {
  final labeled = m.label != null && m.kind == JzMarkerKind.job;
  return Marker(
    point: m.point,
    width: labeled ? 130 : 44,
    height: labeled ? 40 : 44,
    alignment: labeled ? Alignment.center : Alignment.topCenter,
    child: _MarkerChild(marker: m),
  );
}

/// Reprojects markers to the screen on every camera change (via
/// [MapCamera.of]) and groups nearby ones into count bubbles.
class _ClusterLayer extends StatelessWidget {
  const _ClusterLayer({required this.markers, required this.controller});

  final List<JzMapMarker> markers;
  final MapController controller;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final projected = <(JzMapMarker, Offset)>[
      for (final m in markers) (m, camera.latLngToScreenOffset(m.point)),
    ];
    final groups = clusterByGrid(projected, 64);

    final out = <Marker>[];
    for (final g in groups) {
      if (g.length == 1) {
        out.add(_markerFor(g.first));
      } else {
        var lat = 0.0, lng = 0.0;
        for (final m in g) {
          lat += m.point.latitude;
          lng += m.point.longitude;
        }
        final center = LatLng(lat / g.length, lng / g.length);
        out.add(
          Marker(
            point: center,
            width: 46,
            height: 46,
            child: _ClusterBubble(
              count: g.length,
              onTap: () => controller.move(center, camera.zoom + 2),
            ),
          ),
        );
      }
    }
    return MarkerLayer(markers: out);
  }
}

class _MarkerChild extends StatelessWidget {
  const _MarkerChild({required this.marker});
  final JzMapMarker marker;

  @override
  Widget build(BuildContext context) {
    if (marker.label != null && marker.kind == JzMarkerKind.job) {
      final pill = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1F8F4E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          marker.label!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
      return marker.onTap == null
          ? pill
          : GestureDetector(onTap: marker.onTap, child: pill);
    }
    return _Pin(kind: marker.kind, onTap: marker.onTap);
  }
}

class _ClusterBubble extends StatelessWidget {
  const _ClusterBubble({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1F8F4E),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _MeDot extends StatelessWidget {
  const _MeDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D80F2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.kind, this.onTap});
  final JzMarkerKind kind;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isApplicant = kind == JzMarkerKind.applicant;
    final icon = isApplicant
        ? Icons.person_pin_circle_rounded
        : Icons.location_on_rounded;
    final color = isApplicant
        ? const Color(0xFF0D80F2)
        : const Color(0xFF3A36DB);
    final pin = Icon(
      icon,
      color: color,
      size: 40,
      shadows: const [
        Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
      ],
    );
    return onTap == null ? pin : GestureDetector(onTap: onTap, child: pin);
  }
}
