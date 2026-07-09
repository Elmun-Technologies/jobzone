/// Cross-platform map widget — OpenStreetMap (flutter_map) on every platform.
/// The former mobile implementation (Yandex MapKit) was retired: the abandoned
/// `yandex_mapkit` 4.2.1 plugin no longer compiles against current Android
/// tooling (its maps.mobile classes never reach the plugin's javac classpath),
/// which blocked release APK builds. The OSM implementation is feature-parity
/// (clustered salary-pill markers, "me" dot, tap-to-pick) and needs no API key.
library;

export 'jz_map_osm.dart';
export 'jz_map_types.dart';
