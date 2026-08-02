import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/applications/application/applications_controller.dart';
import '../../features/applications/data/applications_repository.dart';
import '../../features/chat/application/chat_providers.dart';
import '../../features/companies/data/company_follow_repository.dart';
import '../../features/employer/data/applicants_repository.dart';
import '../../features/employer/data/company_admin_repository.dart';
import '../../features/employer/data/employer_jobs_repository.dart';
import '../../features/employer/data/employer_stats_provider.dart';
import '../../features/employer/data/wallet_repository.dart';
import '../../features/jobs/application/bookmarks_controller.dart';
import '../../features/jobs/application/dismissed_controller.dart';
import '../../features/jobs/application/jobs_providers.dart';
import '../../features/monetization/data/monetization_repository.dart';
import '../../features/notifications/application/notifications_providers.dart';
import '../../features/notifications/data/telegram_repository.dart';
import '../../features/preferences/application/preferences_controller.dart';
import '../../features/profile/application/cv_providers.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/reviews/data/worker_reviews_repository.dart';
import '../../features/search/data/saved_searches_repository.dart';

/// Providers holding data that belongs to one signed-in account.
///
/// None of these auto-dispose — they live for the process — and each resolves
/// `auth.currentUser` once, when it is first built. So after a sign-out and a
/// sign-in as somebody else, every one of them would still be serving the
/// previous account's data: their applications, bookmarks, résumés, chats and
/// profile, until something happened to invalidate it. On a shared phone that
/// is a privacy leak, not just a stale cache.
///
/// [invalidateAccountScope] is called from the app root whenever the signed-in
/// identity changes (see `currentUserIdProvider`), which covers sign-in,
/// sign-out and account switching in one place.
///
/// **Maintenance:** a new provider that reads per-account data belongs in this
/// list. The alternative — having each one watch `currentUserIdProvider`
/// itself — is self-maintaining but would touch every data file; this keeps
/// the rule in one reviewable place.
///
/// Drops every cached per-account value so the next read refetches for
/// whoever is signed in now. Invalidating a family clears all of its
/// instances, so the `.family` entries need no argument.
void invalidateAccountScope(WidgetRef ref) {
  // Profile & CV
  ref.invalidate(currentProfileProvider);
  ref.invalidate(contactInfoProvider);
  ref.invalidate(experiencesControllerProvider);
  ref.invalidate(educationsControllerProvider);
  ref.invalidate(projectsControllerProvider);
  ref.invalidate(certificationsControllerProvider);
  ref.invalidate(volunteerControllerProvider);
  ref.invalidate(awardsControllerProvider);
  ref.invalidate(skillsControllerProvider);
  ref.invalidate(resumesControllerProvider);

  // Seeker activity
  ref.invalidate(applicationsControllerProvider);
  ref.invalidate(applicationByIdProvider);
  ref.invalidate(statusHistoryProvider);
  ref.invalidate(bookmarksControllerProvider);
  ref.invalidate(bookmarkedJobsProvider);
  ref.invalidate(dismissedControllerProvider);
  ref.invalidate(archivedJobsProvider);
  ref.invalidate(recommendedJobsProvider);
  ref.invalidate(savedSearchesControllerProvider);
  ref.invalidate(preferencesControllerProvider);
  ref.invalidate(followedCompaniesProvider);
  ref.invalidate(followedCompanyJobsProvider);
  ref.invalidate(isFollowingCompanyProvider);
  ref.invalidate(workerReputationProvider);

  // Messaging & notifications
  ref.invalidate(conversationsProvider);
  ref.invalidate(notificationsControllerProvider);
  ref.invalidate(notificationSettingsProvider);
  ref.invalidate(telegramStatusProvider);

  // Employer side
  ref.invalidate(myCompanyProvider);
  ref.invalidate(companyPeopleAdminProvider);
  ref.invalidate(companyGalleryAdminProvider);
  ref.invalidate(myJobsProvider);
  ref.invalidate(allApplicantsProvider);
  ref.invalidate(jobApplicantsProvider);
  // Keyed by the candidate's profile id, but readable only because *this*
  // account is their recruiter — so it is per-account data despite the key.
  ref.invalidate(applicantCertificationsProvider);
  ref.invalidate(employerStatsProvider);
  ref.invalidate(walletProvider);
  ref.invalidate(myOrdersProvider);
}
