/// Cross-platform map widget. Yandex maps on mobile — via the OFFICIAL
/// `yandex_maps_mapkit_lite` SDK (the abandoned community `yandex_mapkit`
/// plugin stopped compiling against current Android tooling) — and
/// OpenStreetMap (flutter_map) on web, selected at compile time so the web
/// build never pulls in the mobile-only native SDK. Both implementations
/// expose the same `JzMapView` API and an `initJzMap()` bootstrap hook
/// (a real SDK init on mobile, a no-op on web).
library;

export 'jz_map_osm.dart' if (dart.library.io) 'jz_map_yandex.dart';
export 'jz_map_types.dart';
