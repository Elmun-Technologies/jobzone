import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'jz_map_types.dart';

/// Yandex MapKit implementation — used on Android/iOS. Requires the native API
/// key (set in MainApplication.kt / AppDelegate.swift). Never compiled for web:
/// `jz_map.dart` only exports this when `dart.library.io` is available.
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
  YandexMapController? _controller;

  Point _toPoint(LatLng ll) =>
      Point(latitude: ll.latitude, longitude: ll.longitude);

  void _move(LatLng point, double zoom) {
    _controller?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _toPoint(point), zoom: zoom),
      ),
    );
  }

  @override
  void dispose() {
    widget.controller?.unbind();
    super.dispose();
  }

  List<PlacemarkMapObject> _objects() => [
    for (final m in widget.markers)
      PlacemarkMapObject(
        mapId: MapObjectId(m.id),
        point: _toPoint(m.point),
        onTap: m.onTap == null ? null : (_, _) => m.onTap!(),
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromAssetImage(
              m.kind == JzMarkerKind.applicant
                  ? 'assets/icon/pin_applicant.png'
                  : 'assets/icon/pin_job.png',
            ),
            anchor: const Offset(0.5, 1),
          ),
        ),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    return YandexMap(
      onMapCreated: (controller) {
        _controller = controller;
        widget.controller?.bind(_move);
        _move(widget.initialCenter, widget.initialZoom);
      },
      mapObjects: _objects(),
      onMapTap: widget.onMapTap == null
          ? null
          : (point) =>
                widget.onMapTap!(LatLng(point.latitude, point.longitude)),
    );
  }
}
