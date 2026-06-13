import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/language_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/chat/presentation/chat_list_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/onboarding/presentation/welcome_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/search/presentation/explore_page.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../../shared/widgets/placeholder_page.dart';
import 'app_shell.dart';
import 'routes.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// The app's [GoRouter]. The `StatefulShellRoute` provides the persistent
/// bottom navigation; detail routes are pushed above it. Auth/onboarding
/// gating is added in the Auth phase via [GoRouter.redirect] + a refresh
/// listenable on auth state.
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(path: Routes.splash, builder: (c, s) => const SplashPage()),
      GoRoute(path: Routes.welcome, builder: (c, s) => const WelcomePage()),
      _stub(Routes.onboarding, 'Onboarding'),

      // Auth
      GoRoute(path: Routes.signIn, builder: (c, s) => const SignInPage()),
      _stub(Routes.createAccount, 'Create Account'),
      _stub(Routes.verifyCode, 'Verify Code'),
      _stub(Routes.newPassword, 'New Password'),
      _stub(Routes.completeProfile, 'Complete Your Profile'),

      // Preference setup
      _stub(Routes.setupJobType, 'Job Type'),
      _stub(Routes.setupExperience, 'Level of Experience'),
      _stub(Routes.setupWorkingModel, 'Working Model'),
      _stub(Routes.setupJobTitle, 'Job Title'),

      // Permissions
      _stub(Routes.permLocation, 'Location Access'),
      _stub(Routes.permLocationManual, 'Manual Location'),
      _stub(Routes.permNotifications, 'Notification Access'),

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
