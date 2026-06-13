import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../features/account/presentation/language_page.dart';
import '../../features/auth/presentation/pages/complete_profile_page.dart';
import '../../features/auth/presentation/pages/create_account_page.dart';
import '../../features/auth/presentation/pages/new_password_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/verify_code_page.dart';
import '../../features/chat/presentation/chat_list_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/onboarding/presentation/welcome_page.dart';
import '../../features/permissions/presentation/location_access_page.dart';
import '../../features/permissions/presentation/manual_location_page.dart';
import '../../features/permissions/presentation/notification_access_page.dart';
import '../../features/preferences/presentation/experience_level_page.dart';
import '../../features/preferences/presentation/job_title_page.dart';
import '../../features/preferences/presentation/job_type_page.dart';
import '../../features/preferences/presentation/working_model_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/search/presentation/explore_page.dart';
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
      _stub(Routes.search, 'Search'),
      _stub(Routes.filter, 'Filter'),

      // Jobs (static before parameterized)
      _stub(Routes.suggestedJobs, 'Suggested Jobs'),
      _stub(Routes.recentJobs, 'Recent Jobs'),
      _stub(Routes.bookmarks, 'Bookmarks'),
      _stub('/jobs/:id', 'Job Details'),
      _stub('/jobs/:id/apply', 'Apply for Job'),
      _stub('/jobs/:id/apply/success', 'Application Sent'),
      _stub('/jobs/:id/review/new', 'Write Company Review'),

      // Companies
      _stub('/companies/:id', 'Company Details'),
      _stub('/companies/:id/intro-video', 'Intro Video'),
      _stub('/companies/:id/gallery', 'Gallery'),

      // Chat detail + calls
      _stub('/chat/:id', 'Chat'),
      _stub('/chat/:id/call/video', 'Video Call'),
      _stub('/chat/:id/call/voice', 'Voice Call'),

      // Notifications
      _stub(Routes.notifications, 'Notifications'),

      // Profile (CV) subtree
      _stub(Routes.profileContactInfo, 'Contact Info'),
      _stub(Routes.profileAbout, 'About Me'),
      _stub(Routes.profileExperience, 'Experience'),
      _stub(Routes.profileEducation, 'Education'),
      _stub(Routes.profileProjects, 'Projects'),
      _stub(Routes.profileCertifications, 'Certifications & Licenses'),
      _stub(Routes.profileVolunteer, 'Volunteer Experience'),
      _stub(Routes.profileAwards, 'Awards & Achievements'),
      _stub(Routes.profileSkills, 'Skills'),
      _stub(Routes.profileResume, 'Resume / CV'),

      // Account subtree
      _stub(Routes.accountPersonalInfo, 'Personal Information'),
      _stub(Routes.accountAnalytics, 'Analytics'),
      _stub(Routes.accountApplications, 'My Applications'),
      _stub(Routes.accountSeekingStatus, 'Job Seeking Status'),
      _stub(Routes.accountSettings, 'Settings'),
      _stub(Routes.accountNotificationSettings, 'Notification Settings'),
      GoRoute(
        path: Routes.accountLanguage,
        builder: (c, s) => const LanguagePage(),
      ),
      _stub(Routes.accountPassword, 'Password Manager'),
      _stub(Routes.accountHelp, 'Help Center'),
      _stub(Routes.accountPrivacy, 'Privacy Policy'),
      _stub(Routes.accountInvite, 'Invite Friends'),
    ],
    errorBuilder: (context, state) =>
        PlaceholderPage(title: state.error?.message ?? 'Not found'),
  );
});

GoRoute _stub(String path, String title) => GoRoute(
  path: path,
  builder: (context, state) => PlaceholderPage(title: title),
);
