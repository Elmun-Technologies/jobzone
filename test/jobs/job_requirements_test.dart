import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/jobs/domain/job.dart';
import 'package:jobzone/features/jobs/domain/job_language.dart';

void main() {
  group('Job requirements parsing', () {
    test('fromMap reads driver_licenses, languages and salary_gross', () {
      final j = Job.fromMap({
        'id': 'j1',
        'driver_licenses': ['B', 'C'],
        'languages': [
          {'code': 'en', 'level': 'b2'},
          {'code': 'ru', 'level': 'native'},
        ],
        'salary_gross': false,
      });
      expect(j.driverLicenses, ['B', 'C']);
      expect(j.languages.length, 2);
      expect(j.languages.first.code, 'en');
      expect(j.languages.first.level, 'b2');
      expect(j.salaryGross, isFalse);
    });

    test('defaults when the columns are absent', () {
      final j = Job.fromMap({'id': 'j2'});
      expect(j.driverLicenses, isEmpty);
      expect(j.languages, isEmpty);
      expect(j.salaryGross, isTrue);
    });

    test('JobLanguage round-trips through its map', () {
      const lang = JobLanguage(code: 'uz', level: 'c1');
      final back = JobLanguage.fromMap(lang.toMap());
      expect(back.code, 'uz');
      expect(back.level, 'c1');
    });
  });
}
