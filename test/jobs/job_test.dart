import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/jobs/domain/job.dart';

void main() {
  group('Job', () {
    test('fromMap parses a job_feed row', () {
      final job = Job.fromMap({
        'id': 'j1',
        'title': 'Engineer',
        'company_id': 'c1',
        'company_name': 'Acme',
        'company_is_verified': true,
        'city': 'Tashkent',
        'country': 'UZ',
        'job_type': 'full_time',
        'salary_min': 1000,
        'salary_max': 2000,
        'currency': 'USD',
        'skills_required': ['Dart', 'Flutter'],
        'applicants_count': 5,
        'posted_at': '2026-06-10T00:00:00Z',
      });
      expect(job.id, 'j1');
      expect(job.companyVerified, isTrue);
      expect(job.locationText, 'Tashkent, UZ');
      expect(job.skills, ['Dart', 'Flutter']);
      expect(job.salaryText, r'$1k - $2k');
      expect(job.postedAt, isNotNull);
    });

    test('salaryText is null when no salary is set', () {
      final job = Job.fromMap({
        'id': 'j',
        'title': 't',
        'company_id': 'c',
        'company_name': 'co',
      });
      expect(job.salaryText, isNull);
    });

    test('salaryText handles a single bound', () {
      final job = Job.fromMap({
        'id': 'j',
        'title': 't',
        'company_id': 'c',
        'company_name': 'co',
        'salary_min': 1500,
        'currency': 'USD',
      });
      expect(job.salaryText, r'$1.5k');
    });
  });
}
