import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../features/account/presentation/analytics_page.dart';
import '../../features/account/presentation/help_center_page.dart';
import '../../features/account/presentation/invite_friends_page.dart';
import '../../features/account/presentation/language_page.dart';
import '../../features/account/presentation/password_manager_page.dart';
import '../../features/account/presentation/personal_info_page.dart';
import '../../features/account/presentation/privacy_policy_page.dart';
import '../../features/account/presentation/seeking_status_page.dart';
import '../../features/account/presentation/settings_page.dart';
import '../../features/applications/domain/application.dart';
import '../../features/applications/presentation/application_status_page.dart';
import '../../features/applications/presentation/application_success_page.dart';
import '../../features/applications/presentation/apply_job_page.dart';
import '../../features/applications/presentation/my_applications_page.dart';
import '../../features/auth/presentation/pages/complete_profile_page.dart';
import '../../features/auth/presentation/pages/create_account_page.dart';
import '../../features/auth/presentation/pages/new_password_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/verify_code_page.dart';
import '../../features/chat/domain/chat_models.dart';
import '../../features/chat/presentation/call_page.dart';
import '../../features/chat/presentation/chat_detail_page.dart';
import '../../features/chat/presentation/chat_list_page.dart';
import '../../features/companies/presentation/company_details_page.dart';
import '../../features/companies/presentation/gallery_page.dart';
import '../../features/companies/presentation/intro_video_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/jobs/presentation/bookmarks_page.dart';
import '../../features/jobs/presentation/job_details_page.dart';
import '../../features/jobs/presentation/see_all_page.dart';
import '../../features/notifications/presentation/notification_settings_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/onboarding/presentation/welcome_page.dart';
import '../../features/permissions/presentation/location_access_page.dart';
import '../../features/permissions/presentation/manual_location_page.dart';
import '../../features/permissions/presentation/notification_access_page.dart';
import '../../features/preferences/presentation/experience_level_page.dart';
import '../../features/preferences/presentation/job_title_page.dart';
import '../../features/preferences/presentation/job_type_page.dart';
import '../../features/preferences/presentation/working_model_page.dart';
import '../../features/profile/presentation/edit/about_edit_page.dart';
import '../../features/profile/presentation/edit/awards_page.dart';
import '../../features/profile/presentation/edit/certifications_page.dart';
import '../../features/profile/presentation/edit/contact_info_page.dart';
import '../../features/profile/presentation/edit/education_page.dart';
import '../../features/profile/presentation/edit/experience_page.dart';
import '../../features/profile/presentation/edit/projects_page.dart';
import '../../features/profile/presentation/edit/resume_page.dart';
import '../../features/profile/presentation/edit/skills_edit_page.dart';
import '../../features/profile/presentation/edit/volunteer_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/profile/presentation/your_profile_page.dart';
import '../../features/reviews/presentation/write_review_page.dart';
import '../../features/search/presentation/explore_page.dart';
import '../../features/search/presentation/filter_page.dart';
import '../../features/search/presentation/search_page.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../../shared/providers/app_flags.dart';
import '../../shared/widgets/placeholder_page.dart';
import 'app_shell.dart';
import 'guards.dart';
import 'routes.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// The app's [GoRouter]. A `StatefulShellRoute` provides the persistent bottom
/// navigation; detail routes are pushed above it. The `redirect` guard (see
/// guards.dart) enforces onboarding → auth → setup → app, and re-runs whenever
/// auth state or onboarding flags change.
final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = RouterRefresh();
  ref.listen(authStateChangesProvider, (_, _) => refresh.bump());
  ref.listen(appFlagsProvider, (_, _) => refresh.bump());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    refreshListenable: refresh,
    redirect: (context, state) => redirectFromRef(ref, state.matchedLocation),
    routes: [
      GoRoute(path: Routes.splash, builder: (c, s) => const SplashPage()),
      GoRoute(path: Routes.welcome, builder: (c, s) => const WelcomePage()),
      GoRoute(
        path: Routes.onboarding,
        builder: (c, s) => const OnboardingPage(),
      ),

      // Auth
      GoRoute(path: Routes.signIn, builder: (c, s) => const SignInPage()),
      GoRoute(
        path: Routes.createAccount,
        builder: (c, s) => const CreateAccountPage(),
      ),
      GoRoute(
        path: Routes.verifyCode,
        builder: (c, s) => VerifyCodePage(args: s.extra as VerifyCodeArgs),
      ),
      GoRoute(
        path: Routes.newPassword,
        builder: (c, s) => const NewPasswordPage(),
      ),
      GoRoute(
        path: Routes.completeProfile,
        builder: (c, s) => const CompleteProfilePage(),
      ),

      // Preference setup
      GoRoute(
        path: Routes.setupJobType,
        builder: (c, s) => const JobTypePage(),
      ),
      GoRoute(
        path: Routes.setupExperience,
        builder: (c, s) => const ExperienceLevelPage(),
      ),
      GoRoute(
        path: Routes.setupWorkingModel,
        builder: (c, s) => const WorkingModelPage(),
      ),
      GoRoute(
        path: Routes.setupJobTitle,
        builder: (c, s) => const JobTitlePage(),
      ),

      // Permissions
      GoRoute(
        path: Routes.permLocation,
        builder: (c, s) => const LocationAccessPage(),
      ),
      GoRoute(
        path: Routes.permLocationManual,
        builder: (c, s) => const ManualLocationPage(),
      ),
      GoRoute(
        path: Routes.permNotifications,
        builder: (c, s) => const NotificationAccessPage(),
      ),

      // Main bottom-navigation shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.home, builder: (c, s) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.explore,
                builder: (c, s) => const ExplorePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.chat,
                builder: (c, s) => const ChatListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (c, s) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),

      // Explore children
      GoRoute(path: Routes.search, builder: (c, s) => const SearchPage()),
      GoRoute(path: Routes.filter, builder: (c, s) => const FilterPage()),

      // Jobs (static before parameterized)
      GoRoute(
        path: Routes.suggestedJobs,
        builder: (c, s) => const SeeAllJobsPage(kind: SeeAllKind.suggested),
      ),
      GoRoute(
        path: Routes.recentJobs,
        builder: (c, s) => const SeeAllJobsPage(kind: SeeAllKind.recent),
      ),
      GoRoute(path: Routes.bookmarks, builder: (c, s) => const BookmarksPage()),
      GoRoute(
        path: '/jobs/:id',
        builder: (c, s) => JobDetailsPage(jobId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/jobs/:id/apply',
        builder: (c, s) => ApplyJobPage(jobId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/jobs/:id/apply/success',
        builder: (c, s) => const ApplicationSuccessPage(),
      ),
      // Companies
      GoRoute(
        path: '/companies/:id',
        builder: (c, s) =>
            CompanyDetailsPage(companyId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/companies/:id/intro-video',
        builder: (c, s) => IntroVideoPage(
          companyId: s.pathParameters['id']!,
          videoUrl: s.extra as String?,
        ),
      ),
      GoRoute(
        path: '/companies/:id/gallery',
        builder: (c, s) => GalleryPage(companyId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/companies/:id/review/new',
        builder: (c, s) => WriteReviewPage(
          companyId: s.pathParameters['id']!,
          companyName: s.extra as String?,
        ),
      ),

      // Chat detail + calls
      GoRoute(
        path: '/chat/:id',
        builder: (c, s) => ChatDetailPage(
          conversationId: s.pathParameters['id']!,
          preview: s.extra as Conversation?,
        ),
      ),
      GoRoute(
        path: '/chat/:id/call/video',
        builder: (c, s) => CallPage(
          conversationId: s.pathParameters['id']!,
          isVideo: true,
          peer: s.extra as Conversation?,
        ),
      ),
      GoRoute(
        path: '/chat/:id/call/voice',
        builder: (c, s) => CallPage(
          conversationId: s.pathParameters['id']!,
          isVideo: false,
          peer: s.extra as Conversation?,
        ),
      ),

      // Notifications
      GoRoute(
        path: Routes.notifications,
        builder: (c, s) => const NotificationsPage(),
      ),

      // Your Profile (CV read view)
      GoRoute(
        path: Routes.yourProfile,
        builder: (c, s) => const YourProfilePage(),
      ),

      // Profile (CV) subtree
      GoRoute(
        path: Routes.profileContactInfo,
        builder: (c, s) => const ContactInfoPage(),
      ),
      GoRoute(
        path: Routes.profileAbout,
        builder: (c, s) => const AboutEditPage(),
      ),
      GoRoute(
        path: Routes.profileExperience,
        builder: (c, s) => const ExperienceListPage(),
      ),
      GoRoute(
        path: Routes.profileEducation,
        builder: (c, s) => const EducationListPage(),
      ),
      GoRoute(
        path: Routes.profileProjects,
        builder: (c, s) => const ProjectsListPage(),
      ),
      GoRoute(
        path: Routes.profileCertifications,
        builder: (c, s) => const CertificationsListPage(),
      ),
      GoRoute(
        path: Routes.profileVolunteer,
        builder: (c, s) => const VolunteerListPage(),
      ),
      GoRoute(
        path: Routes.profileAwards,
        builder: (c, s) => const AwardsListPage(),
      ),
      GoRoute(
        path: Routes.profileSkills,
        builder: (c, s) => const SkillsEditPage(),
      ),
      GoRoute(
        path: Routes.profileResume,
        builder: (c, s) => const ResumePage(),
      ),

      // Account subtree
      GoRoute(
        path: Routes.accountPersonalInfo,
        builder: (c, s) => const PersonalInfoPage(),
      ),
      GoRoute(
        path: Routes.accountAnalytics,
        builder: (c, s) => const AnalyticsPage(),
      ),
      GoRoute(
        path: Routes.accountApplications,
        builder: (c, s) => const MyApplicationsPage(),
      ),
      GoRoute(
        path: '/account/my-applications/:id',
        builder: (c, s) =>
            ApplicationStatusPage(application: s.extra as Application?),
      ),
      GoRoute(
        path: Routes.accountSeekingStatus,
        builder: (c, s) => const SeekingStatusPage(),
      ),
      GoRoute(
        path: Routes.accountSettings,
        builder: (c, s) => const SettingsPage(),
      ),
      GoRoute(
        path: Routes.accountNotificationSettings,
        builder: (c, s) => const NotificationSettingsPage(),
      ),
      GoRoute(
        path: Routes.accountLanguage,
        builder: (c, s) => const LanguagePage(),
      ),
      GoRoute(
        path: Routes.accountPassword,
        builder: (c, s) => const PasswordManagerPage(),
      ),
      GoRoute(
        path: Routes.accountHelp,
        builder: (c, s) => const HelpCenterPage(),
      ),
      GoRoute(
        path: Routes.accountPrivacy,
        builder: (c, s) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: Routes.accountInvite,
        builder: (c, s) => const InviteFriendsPage(),
      ),
    ],
    errorBuilder: (context, state) =>
        PlaceholderPage(title: state.error?.message ?? 'Not found'),
  );
});
