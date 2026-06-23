import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'jz_map_types.dart';
import 'marker_bitmaps.dart';

/// Yandex MapKit implementation — used on Android/iOS. Requires the native API
/// key (set in MainApplication.kt / AppDelegate.swift). Never compiled for web:
/// `jz_map.dart` only exports this when `dart.library.io` is available.
///
/// Supports native clustering (green count bubbles) and salary-pill markers,
/// both rendered to bitmaps by [MarkerBitmaps].
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
  YandexMapController? _controller;

  /// Salary-pill icons keyed by label; built asynchronously from bitmaps.
  final _pillIcons = <String, BitmapDescriptor>{};

  /// Logo+salary marker icons keyed by "url|label".
  final _logoIcons = <String, BitmapDescriptor>{};

  /// Decoded company logos keyed by URL (so each logo is fetched once).
  final _logoImages = <String, ui.Image>{};
  BitmapDescriptor? _meIcon;

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
  void initState() {
    super.initState();
    _buildIcons();
  }

  @override
  void didUpdateWidget(covariant JzMapView old) {
    super.didUpdateWidget(old);
    _buildIcons();
  }

  /// Renders any missing pill / logo / "me" bitmaps, then repaints once ready.
  /// Logos are fetched over the network; until one arrives (or if it fails) the
  /// marker shows the salary pill, which is always built when there's a label.
  Future<void> _buildIcons() async {
    var changed = false;
    for (final m in widget.markers) {
      final label = m.label;
      if (label != null && !_pillIcons.containsKey(label)) {
        _pillIcons[label] = BitmapDescriptor.fromBytes(
          await MarkerBitmaps.salaryPill(label),
        );
        changed = true;
      }
      final url = m.imageUrl;
      if (m.kind == JzMarkerKind.job && url != null && url.isNotEmpty) {
        final key = '$url|${label ?? ''}';
        if (!_logoIcons.containsKey(key)) {
          final img = await _logoImage(url);
          if (img != null) {
            _logoIcons[key] = BitmapDescriptor.fromBytes(
              await MarkerBitmaps.markerWithLogo(
                cacheKey: key,
                logo: img,
                label: label,
              ),
            );
            changed = true;
          }
        }
      }
    }
    if (widget.myLocation != null && _meIcon == null) {
      _meIcon = BitmapDescriptor.fromBytes(await MarkerBitmaps.meDot());
      changed = true;
    }
    if (changed && mounted) setState(() {});
  }

  /// Fetches + decodes a logo, caching by URL. Null on any network/decode error.
  Future<ui.Image?> _logoImage(String url) async {
    final cached = _logoImages[url];
    if (cached != null) return cached;
    try {
      final client = HttpClient();
      final resp = await (await client.getUrl(Uri.parse(url))).close();
      if (resp.statusCode != 200) {
        client.close();
        return null;
      }
      final bytes = await consolidateHttpClientResponseBytes(resp);
      client.close();
      final img = await MarkerBitmaps.decodeImage(bytes);
      _logoImages[url] = img;
      return img;
    } catch (_) {
      return null;
    }
  }

  PlacemarkIcon _iconFor(JzMapMarker m) {
    final url = m.imageUrl;
    if (m.kind == JzMarkerKind.job && url != null && url.isNotEmpty) {
      final logo = _logoIcons['$url|${m.label ?? ''}'];
      if (logo != null) {
        return PlacemarkIcon.single(
          PlacemarkIconStyle(image: logo, anchor: const Offset(0.5, 0.5)),
        );
      }
    }
    final pill = m.label == null ? null : _pillIcons[m.label];
    if (pill != null) {
      return PlacemarkIcon.single(
        PlacemarkIconStyle(image: pill, anchor: const Offset(0.5, 0.5)),
      );
    }
    // Fallback (and applicant/picked kinds): the asset pin, anchored at its tip.
    return PlacemarkIcon.single(
      PlacemarkIconStyle(
        image: BitmapDescriptor.fromAssetImage(
          m.kind == JzMarkerKind.applicant
              ? 'assets/icon/pin_applicant.png'
              : 'assets/icon/pin_job.png',
        ),
        anchor: const Offset(0.5, 1),
      ),
    );
  }

  PlacemarkMapObject _placemark(JzMapMarker m) => PlacemarkMapObject(
    mapId: MapObjectId(m.id),
    point: _toPoint(m.point),
    onTap: m.onTap == null ? null : (_, _) => m.onTap!(),
    icon: _iconFor(m),
  );

  List<MapObject> _objects() {
    final objects = <MapObject>[];
    final placemarks = [for (final m in widget.markers) _placemark(m)];

    if (widget.cluster) {
      objects.add(
        ClusterizedPlacemarkCollection(
          mapId: const MapObjectId('jz-cluster'),
          placemarks: placemarks,
          radius: 60,
          minZoom: 15,
          onClusterAdded: (self, cluster) async {
            final bytes = await MarkerBitmaps.clusterBubble(cluster.size);
            return cluster.copyWith(
              appearance: cluster.appearance.copyWith(
                icon: PlacemarkIcon.single(
                  PlacemarkIconStyle(image: BitmapDescriptor.fromBytes(bytes)),
                ),
              ),
            );
          },
          onClusterTap: (self, cluster) {
            final p = cluster.appearance.point;
            _move(LatLng(p.latitude, p.longitude), 14);
          },
        ),
      );
    } else {
      objects.addAll(placemarks);
    }

    if (widget.myLocation != null && _meIcon != null) {
      objects.add(
        PlacemarkMapObject(
          mapId: const MapObjectId('jz-me'),
          point: _toPoint(widget.myLocation!),
          icon: PlacemarkIcon.single(PlacemarkIconStyle(image: _meIcon!)),
        ),
      );
    }
    return objects;
  }

  @override
  void dispose() {
    widget.controller?.unbind();
    super.dispose();
  }

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
