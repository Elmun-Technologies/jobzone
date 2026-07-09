import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:yandex_maps_mapkit_lite/image.dart' as ymk_image;
import 'package:yandex_maps_mapkit_lite/init.dart' as ymk_init;
import 'package:yandex_maps_mapkit_lite/mapkit.dart' as ymk;
import 'package:yandex_maps_mapkit_lite/mapkit_factory.dart' show mapkit;
import 'package:yandex_maps_mapkit_lite/yandex_map.dart' show YandexMap;

import 'jz_map_types.dart';
import 'marker_bitmaps.dart';

/// Yandex MapKit API key. App-id-restricted (io.jobzone.jobzone), so it is
/// safe to commit — same model as a Google Maps key. Manage it at
/// https://developer.tech.yandex.ru/.
const _yandexApiKey = '1d02f6b0-05d4-4eb6-ae5b-eea72724a6ff';

/// One-time Yandex MapKit init; `bootstrap()` awaits this before `runApp`.
/// The web (OSM) implementation exposes a no-op with the same signature.
Future<void> initJzMap() => ymk_init.initMapkit(apiKey: _yandexApiKey);

/// Yandex map implementation — Android/iOS, on the OFFICIAL
/// `yandex_maps_mapkit_lite` SDK (the abandoned community `yandex_mapkit`
/// plugin no longer compiles against current Android tooling). Never compiled
/// for web: `jz_map.dart` only exports this when `dart.library.io` exists.
///
/// Feature parity with the OSM implementation: native clustering (green count
/// bubbles), salary-pill / company-logo markers (rendered to bitmaps by
/// [MarkerBitmaps]), a "me" dot, tap-to-pick, and a [JzMapController] seam.
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
  ymk.MapWindow? _window;

  /// Our own child collection under the map's root, so a rebuild can clear
  /// just our objects without touching anything else on the map.
  ymk.MapObjectCollection? _layer;

  /// Placemarks by marker id — lets a semantically-equal update refresh only
  /// `userData` (fresh onTap closures) instead of re-adding every object.
  final _placemarks = <String, ymk.PlacemarkMapObject>{};

  /// What the current native objects were built from; guards against churny
  /// parent rebuilds re-adding identical placemarks (icon flicker).
  List<String>? _builtSignature;

  // The SDK holds only weak references to listeners — these fields are the
  // strong references that keep them alive while attached.
  late final _tapListener = _PlacemarkTapListener();
  late final _clusterHandler = _ClusterHandler(this);
  _MapTapListener? _inputListener;

  /// Decoded company logos keyed by URL (each fetched once per session).
  static final _logoImages = <String, ui.Image>{};

  ymk.Point _toPoint(LatLng ll) =>
      ymk.Point(latitude: ll.latitude, longitude: ll.longitude);

  void _move(LatLng point, double zoom) {
    _window?.map.move(
      ymk.CameraPosition(_toPoint(point), zoom: zoom, azimuth: 0, tilt: 0),
      animation: const ymk.Animation(
        type: ymk.AnimationType.Smooth,
        duration: 0.3,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    mapkit.onStart();
  }

  void _onMapCreated(ymk.MapWindow window) {
    _window = window;
    widget.controller?.bind(_move);
    window.map.move(
      ymk.CameraPosition(
        _toPoint(widget.initialCenter),
        zoom: widget.initialZoom,
        azimuth: 0,
        tilt: 0,
      ),
    );
    if (widget.onMapTap != null) {
      final listener = _MapTapListener(
        (p) => widget.onMapTap?.call(p), // reads the latest widget's callback
      );
      _inputListener = listener;
      window.map.addInputListener(listener);
    }
    _layer = window.map.mapObjects.addCollection();
    _rebuildObjects();
  }

  @override
  void didUpdateWidget(covariant JzMapView old) {
    super.didUpdateWidget(old);
    _rebuildObjects();
  }

  List<String> _signature() => [
    for (final m in widget.markers)
      '${m.id}|${m.point.latitude}|${m.point.longitude}|'
          '${m.label}|${m.imageUrl}|${m.kind}',
    'cluster:${widget.cluster}',
    'me:${widget.myLocation?.latitude},${widget.myLocation?.longitude}',
  ];

  void _rebuildObjects() {
    final layer = _layer;
    if (layer == null) return;

    final sig = _signature();
    if (listEquals(sig, _builtSignature)) {
      // Same pins — just refresh userData so taps use the latest closures.
      for (final m in widget.markers) {
        _placemarks[m.id]?.userData = m;
      }
      return;
    }
    _builtSignature = sig;

    layer.clear();
    _placemarks.clear();

    if (widget.cluster) {
      final clustered = layer.addClusterizedPlacemarkCollection(
        _clusterHandler,
      );
      for (final m in widget.markers) {
        _decorate(clustered.addPlacemarkWithPoint(_toPoint(m.point)), m);
      }
      clustered.clusterPlacemarks(clusterRadius: 60, minZoom: 15);
    } else {
      for (final m in widget.markers) {
        _decorate(layer.addPlacemarkWithPoint(_toPoint(m.point)), m);
      }
    }

    final me = widget.myLocation;
    if (me != null) {
      layer
          .addPlacemarkWithPoint(_toPoint(me))
          .setIconWithStyle(
            ymk_image.ImageProvider(
              () async => (await MarkerBitmaps.meDot()).clone(),
              id: 'jz:me',
            ),
            _centered,
          );
    }
  }

  static const _centered = ymk.IconStyle(anchor: math.Point(0.5, 0.5));
  static const _tipAnchored = ymk.IconStyle(anchor: math.Point(0.5, 1.0));

  void _decorate(ymk.PlacemarkMapObject placemark, JzMapMarker m) {
    placemark.userData = m;
    placemark.addTapListener(_tapListener);
    _placemarks[m.id] = placemark;

    final url = m.imageUrl;
    final label = m.label;
    if (m.kind == JzMarkerKind.job && url != null && url.isNotEmpty) {
      // Logo marker; the provider itself fetches the logo and falls back to
      // the salary pill (or the asset pin) if the fetch/decode fails.
      placemark.setIconWithStyle(
        ymk_image.ImageProvider(() async {
          final logo = await _logoImage(url);
          if (logo != null) {
            final img = await MarkerBitmaps.markerWithLogo(
              cacheKey: '$url|${label ?? ''}',
              logo: logo,
              label: label,
            );
            return img.clone();
          }
          if (label != null) {
            return (await MarkerBitmaps.salaryPill(label)).clone();
          }
          return _assetImage('assets/icon/pin_job.png');
        }, id: 'jz:logo:$url|${label ?? ''}'),
        _centered,
      );
      return;
    }
    if (label != null) {
      placemark.setIconWithStyle(
        ymk_image.ImageProvider(
          () async => (await MarkerBitmaps.salaryPill(label)).clone(),
          id: 'jz:pill:$label',
        ),
        _centered,
      );
      return;
    }
    // Fallback (and applicant/picked kinds): the asset pin, tip-anchored.
    final asset = m.kind == JzMarkerKind.applicant
        ? 'assets/icon/pin_applicant.png'
        : 'assets/icon/pin_job.png';
    placemark.setIconWithStyle(
      ymk_image.ImageProvider(() => _assetImage(asset), id: 'jz:asset:$asset'),
      _tipAnchored,
    );
  }

  /// Fetches + decodes a logo, caching by URL. Null on any network/decode
  /// error (the caller falls back to the pill/pin).
  static Future<ui.Image?> _logoImage(String url) async {
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

  static Future<ui.Image> _assetImage(String path) async {
    final data = await rootBundle.load(path);
    return MarkerBitmaps.decodeImage(data.buffer.asUint8List());
  }

  @override
  void dispose() {
    widget.controller?.unbind();
    // The platform view (and with it the native map) may already be gone by
    // the time Flutter disposes this state; cleanup is best-effort.
    try {
      final listener = _inputListener;
      if (listener != null) _window?.map.removeInputListener(listener);
    } catch (_) {}
    mapkit.onStop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => YandexMap(onMapCreated: _onMapCreated);
}

/// Routes a placemark tap to its marker's `onTap` (stored in `userData`).
final class _PlacemarkTapListener implements ymk.MapObjectTapListener {
  @override
  bool onMapObjectTap(ymk.MapObject mapObject, ymk.Point point) {
    final m = mapObject.userData;
    if (m is JzMapMarker && m.onTap != null) {
      m.onTap!();
      return true;
    }
    return false;
  }
}

/// Map-background taps → the widget's `onMapTap` with a [LatLng].
final class _MapTapListener implements ymk.MapInputListener {
  _MapTapListener(this._onTap);

  final void Function(LatLng point) _onTap;

  @override
  void onMapTap(ymk.Map map, ymk.Point point) =>
      _onTap(LatLng(point.latitude, point.longitude));

  @override
  void onMapLongTap(ymk.Map map, ymk.Point point) {}
}

/// Draws each new cluster as a green count bubble and zooms in when tapped.
final class _ClusterHandler
    implements ymk.ClusterListener, ymk.ClusterTapListener {
  _ClusterHandler(this._state);

  final _JzMapViewState _state;

  @override
  void onClusterAdded(ymk.Cluster cluster) {
    final size = cluster.size;
    cluster.appearance.setIconWithStyle(
      ymk_image.ImageProvider(
        () async => (await MarkerBitmaps.clusterBubble(size)).clone(),
        id: 'jz:cluster:$size',
      ),
      _JzMapViewState._centered,
    );
    cluster.addClusterTapListener(this);
  }

  @override
  bool onClusterTap(ymk.Cluster cluster) {
    final p = cluster.appearance.geometry;
    _state._move(LatLng(p.latitude, p.longitude), 14);
    return true;
  }
}
