import '../../companies/domain/company.dart';

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
}

/// Process-wide offline employer instance.
final mockEmployer = MockEmployer();
