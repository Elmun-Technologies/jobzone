import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/shared/widgets/jz_map/cluster_grid.dart';

void main() {
  group('clusterByGrid', () {
    test('groups points in the same cell and separates distant ones', () {
      final groups = clusterByGrid<String>(const [
        ('a', Offset(10, 10)),
        ('b', Offset(20, 20)), // same 64px cell as a
        ('c', Offset(500, 500)), // far away → its own cell
      ], 64);

      expect(groups.length, 2);
      final sizes = groups.map((g) => g.length).toList()..sort();
      expect(sizes, [1, 2]);
    });

    test('a smaller cell size splits points that were together', () {
      final points = [('a', const Offset(10, 10)), ('b', const Offset(40, 40))];
      expect(clusterByGrid(points, 64).length, 1); // same cell
      expect(clusterByGrid(points, 16).length, 2); // different cells
    });

    test('empty input yields no clusters', () {
      expect(clusterByGrid<String>(const [], 64), isEmpty);
    });
  });
}
