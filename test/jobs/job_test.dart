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

    test('parses blue-collar fit fields and groups UZS salary', () {
      final job = Job.fromMap({
        'id': 'j1',
        'title': 'Welder',
        'company_id': 'c1',
        'company_name': 'Acme',
        'job_type': 'rotational',
        'schedule_pattern': '6_1',
        'hours_per_day': 12,
        'night_shift': true,
        'formalization': 'employment_contract',
        'currency': 'UZS',
        'salary_min': 2500000,
        'salary_max': 3000000,
        'category_id': 'driver',
      });
      expect(job.jobType, 'rotational');
      expect(job.schedulePattern, '6_1');
      expect(job.hoursPerDay, 12);
      expect(job.nightShift, isTrue);
      expect(job.formalization, 'employment_contract');
      expect(job.categoryId, 'driver');
      expect(job.salaryText, "2 500 000 - 3 000 000 so'm");
    });

    test('fit fields default safely when absent', () {
      final job = Job.fromMap({
        'id': 'j2',
        'title': 'x',
        'company_id': 'c1',
        'company_name': 'Acme',
      });
      expect(job.nightShift, isFalse);
      expect(job.schedulePattern, isNull);
      expect(job.formalization, isNull);
    });
  });
}
