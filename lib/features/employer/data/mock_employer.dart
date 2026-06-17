import 'package:flutter/foundation.dart';

import '../../companies/domain/company.dart';
import '../../jobs/data/mock_jobs.dart';
import '../../jobs/domain/job.dart';

/// Offline (no-backend) employer identity. The created company lives here so
/// the employer screens have data without Supabase. The id is fixed to the
/// richly-seeded `c-acme` so later phases (My Jobs, Applicants, Gallery) line
/// up with the existing mock jobs/people/gallery that already reference it.
class MockEmployer {
  /// The company the offline employer owns. `null` until create-company
  /// onboarding runs; set by [CompanyAdminRepository.createCompany].
  Company? company;

  /// Stable company id shared with the mock jobs/people/gallery seeds.
  static const companyId = 'c-acme';

  /// Mutable copy of this employer's jobs, lazily seeded from the c-acme mock
  /// jobs so offline create/close operations persist across reads.
  List<Job>? _jobs;
  List<Job> get jobs => _jobs ??= [
    for (final j in mockJobs)
      if (j.companyId == companyId) j,
  ];

  /// Mutable team/recruiter list, lazily seeded.
  List<CompanyPerson>? _people;
  List<CompanyPerson> get people => _people ??= [
    const CompanyPerson(
      id: 'p1',
      name: 'Dilnoza Yusupova',
      title: 'Head of Talent',
      isRecruiter: true,
    ),
    const CompanyPerson(
      id: 'p2',
      name: 'Sardor Aliyev',
      title: 'Engineering Manager',
    ),
  ];

  /// Mutable gallery list, lazily seeded.
  List<GalleryItem>? _gallery;
  List<GalleryItem> get gallery => _gallery ??= [
    const GalleryItem(
      id: 'g1',
      mediaUrl: 'https://picsum.photos/seed/acme1/600/600',
      caption: 'Our office',
    ),
    const GalleryItem(
      id: 'g2',
      mediaUrl: 'https://picsum.photos/seed/acme2/600/600',
    ),
  ];

  /// Re-seeds the in-memory stores (and clears the company) so tests start fresh.
  @visibleForTesting
  void resetJobsForTest() {
    _jobs = null;
    _people = null;
    _gallery = null;
    company = null;
  }
}

/// Process-wide offline employer instance.
final mockEmployer = MockEmployer();
