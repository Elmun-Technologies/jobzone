import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'jz_map_types.dart';

/// OpenStreetMap (flutter_map) implementation — used on web (where Yandex
/// MapKit has no support) and as the keyless fallback. Mirrors the original
/// Explore/picker map setup.
class JzMapView extends StatefulWidget {
  const JzMapView({
    super.key,
    required this.initialCenter,
    this.initialZoom = 12,
    this.markers = const [],
    this.onMapTap,
    this.controller,
  });

  final LatLng initialCenter;
  final double initialZoom;
  final List<JzMapMarker> markers;
  final void Function(LatLng point)? onMapTap;
  final JzMapController? controller;

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
        MarkerLayer(
          markers: [
            for (final m in widget.markers)
              Marker(
                point: m.point,
                width: 44,
                height: 44,
                alignment: Alignment.topCenter,
                child: _Pin(kind: m.kind, onTap: m.onTap),
              ),
          ],
        ),
      ],
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
