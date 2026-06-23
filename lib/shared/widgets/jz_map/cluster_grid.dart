import 'dart:ui';

/// Groups items into clusters by snapping their **screen** positions to a square
/// grid of [cell] pixels. Pure (no map/engine state), so it's unit-testable:
/// callers project lat/lng to screen offsets first, then pass them here. Items
/// landing in the same grid cell become one cluster.
///
/// Used by the web (OSM) map; Yandex clusters natively on the device.
List<List<T>> clusterByGrid<T>(List<(T, Offset)> points, double cell) {
  final cells = <String, List<T>>{};
  for (final (item, pos) in points) {
    final cx = (pos.dx / cell).floor();
    final cy = (pos.dy / cell).floor();
    (cells['$cx:$cy'] ??= <T>[]).add(item);
  }
  return cells.values.toList(growable: false);
}
