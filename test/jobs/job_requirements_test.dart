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

  group('Job response settings parsing', () {
    test('fromMap reads the response-setting flags + contact phone', () {
      final j = Job.fromMap({
        'id': 'j3',
        'require_cover_letter': true,
        'disability_friendly': true,
        'allow_incomplete_resume': true,
        'show_phone_on_listing': true,
        'contact_phone': '+998901234567',
      });
      expect(j.requireCoverLetter, isTrue);
      expect(j.disabilityFriendly, isTrue);
      expect(j.allowIncompleteResume, isTrue);
      expect(j.showPhoneOnListing, isTrue);
      expect(j.contactPhone, '+998901234567');
    });

    test('defaults when the columns are absent', () {
      final j = Job.fromMap({'id': 'j4'});
      expect(j.requireCoverLetter, isFalse);
      expect(j.disabilityFriendly, isFalse);
      expect(j.allowIncompleteResume, isFalse);
      expect(j.showPhoneOnListing, isFalse);
      expect(j.contactPhone, isNull);
    });

    test('parses publish_at when scheduled, null otherwise', () {
      final j = Job.fromMap({'id': 'j5', 'publish_at': '2030-01-02T09:00:00Z'});
      expect(j.publishAt, isNotNull);
      expect(j.publishAt!.year, 2030);
      expect(Job.fromMap({'id': 'j6'}).publishAt, isNull);
    });
  });
}
