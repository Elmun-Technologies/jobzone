import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/jobs/domain/job.dart';

void main() {
  final base = Job(
    id: 'j1',
    title: 'Barista',
    companyId: 'c1',
    companyName: 'Acme',
    salaryMin: 1000000,
    salaryMax: 5000000,
    publishAt: DateTime(2030, 1, 1),
  );

  group('Job.copyWith nullable clearing', () {
    test('leaves nullable fields unchanged when not passed', () {
      final c = base.copyWith(title: 'Senior Barista');
      expect(c.salaryMin, 1000000);
      expect(c.salaryMax, 5000000);
      expect(c.publishAt, DateTime(2030, 1, 1));
    });

    test(
      'clears nullable fields when null is passed (un-schedule, clear max)',
      () {
        final c = base.copyWith(
          salaryMin: null,
          salaryMax: null,
          publishAt: null,
        );
        expect(c.salaryMin, isNull);
        expect(c.salaryMax, isNull);
        expect(c.publishAt, isNull);
      },
    );

    test('sets a new value when one is passed', () {
      final c = base.copyWith(
        salaryMax: 9000000,
        publishAt: DateTime(2031, 2, 3),
      );
      expect(c.salaryMax, 9000000);
      expect(c.publishAt, DateTime(2031, 2, 3));
    });
  });
}
