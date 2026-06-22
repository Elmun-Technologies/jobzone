/// Cross-platform map widget. Yandex MapKit on mobile (where it's supported),
/// OpenStreetMap (flutter_map) on web — selected at compile time so the web
/// build never pulls in the mobile-only `yandex_mapkit`. Both implementations
/// expose the same `JzMapView` API.
library;

export 'jz_map_osm.dart' if (dart.library.io) 'jz_map_yandex.dart';
export 'jz_map_types.dart';
