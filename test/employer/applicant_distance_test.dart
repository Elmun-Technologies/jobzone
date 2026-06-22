import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/core/utils/geo.dart';
import 'package:jobzone/features/employer/data/mock_applicants.dart';
import 'package:jobzone/features/employer/presentation/applicants/widgets/applicant_sort_bar.dart';

void main() {
  group('geoDistanceKm', () {
    test('Tashkent → Samarkand is ~270 km', () {
      final d = geoDistanceKm(41.3111, 69.2797, 39.6270, 66.9750)!;
      expect(d, greaterThan(250));
      expect(d, lessThan(290));
    });

    test('nearby points are a short distance', () {
      final d = geoDistanceKm(41.3200, 69.2750, 41.3111, 69.2797)!;
      expect(d, lessThan(3));
    });

    test('returns null when any coordinate is missing', () {
      expect(geoDistanceKm(null, 69.2, 41.3, 69.3), isNull);
      expect(geoDistanceKm(41.3, null, 41.3, 69.3), isNull);
    });
  });

  group('formatKm', () {
    test('formats sub-kilometer as meters', () {
      expect(formatKm(0.75), '750 m');
    });

    test('formats kilometers with one decimal', () {
      expect(formatKm(5.234), '5.2 km');
    });
  });

  group('Applicant.distanceKm', () {
    test('is computed from candidate + job coords in the seed', () {
      final byId = {for (final a in seedApplicants()) a.id: a};
      expect(byId['app-1']!.distanceKm, isNotNull);
      expect(byId['app-1']!.distanceKm! < byId['app-2']!.distanceKm!, isTrue);
    });
  });

  group('sortApplicants', () {
    test('newest keeps the incoming (applied_at desc) order', () {
      final list = seedApplicants();
      expect(sortApplicants(list, ApplicantSort.newest), same(list));
    });

    test('nearest orders by ascending distance', () {
      final sorted = sortApplicants(seedApplicants(), ApplicantSort.nearest);
      expect(sorted.map((a) => a.id).toList(), [
        'app-1',
        'app-3',
        'app-4',
        'app-2',
      ]);
    });
  });
}
