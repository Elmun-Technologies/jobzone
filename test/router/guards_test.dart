import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/app/router/guards.dart';
import 'package:jobzone/app/router/routes.dart';
import 'package:jobzone/shared/enums/enums.dart';

void main() {
  group('resolveRedirect', () {
    test('offline / no-backend mode never redirects', () {
      expect(
        resolveRedirect(
          hasSupabase: false,
          signedIn: false,
          onboardingSeen: false,
          profileComplete: false,
          location: Routes.home,
        ),
        isNull,
      );
    });

    test('splash is left alone', () {
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: false,
          onboardingSeen: false,
          profileComplete: false,
          location: Routes.splash,
        ),
        isNull,
      );
    });

    test('unseen onboarding redirects to onboarding', () {
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: false,
          onboardingSeen: false,
          profileComplete: false,
          location: Routes.home,
        ),
        Routes.onboarding,
      );
    });

    test('seen onboarding but signed out redirects to sign in', () {
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: false,
          onboardingSeen: true,
          profileComplete: false,
          location: Routes.home,
        ),
        Routes.signIn,
      );
    });

    test('signed out may stay on auth routes', () {
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: false,
          onboardingSeen: true,
          profileComplete: false,
          location: Routes.createAccount,
        ),
        isNull,
      );
    });

    test('signed in with incomplete profile redirects to complete profile', () {
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: true,
          onboardingSeen: true,
          profileComplete: false,
          roleChosen: true,
          location: Routes.home,
        ),
        Routes.completeProfile,
      );
    });

    test('signed in with incomplete profile may stay in setup', () {
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: true,
          onboardingSeen: true,
          profileComplete: false,
          roleChosen: true,
          location: Routes.setupJobType,
        ),
        isNull,
      );
    });

    test('fully onboarded user is sent home from auth screens', () {
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: true,
          onboardingSeen: true,
          profileComplete: true,
          location: Routes.signIn,
        ),
        Routes.home,
      );
    });

    test('fully onboarded user can browse the app', () {
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: true,
          onboardingSeen: true,
          profileComplete: true,
          location: Routes.home,
        ),
        isNull,
      );
    });
  });

  group('resolveRedirect — first-run language', () {
    test('onboarded user who has not chosen a language is sent to the '
        'language picker', () {
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: false,
          onboardingSeen: true,
          languageChosen: false,
          profileComplete: false,
          location: Routes.home,
        ),
        Routes.chooseLanguage,
      );
    });

    test('user may stay on the language picker until they choose', () {
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: false,
          onboardingSeen: true,
          languageChosen: false,
          profileComplete: false,
          location: Routes.chooseLanguage,
        ),
        isNull,
      );
    });

    test('language gate comes after onboarding, not before', () {
      // Onboarding still wins when nothing is seen yet.
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: false,
          onboardingSeen: false,
          languageChosen: false,
          profileComplete: false,
          location: Routes.home,
        ),
        Routes.onboarding,
      );
    });

    test('once chosen, the picker sends the user on to sign in', () {
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: false,
          onboardingSeen: true,
          languageChosen: true,
          profileComplete: false,
          location: Routes.chooseLanguage,
        ),
        Routes.signIn,
      );
    });

    test('a fully onboarded user is bounced off the first-run picker', () {
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: true,
          onboardingSeen: true,
          languageChosen: true,
          profileComplete: true,
          location: Routes.chooseLanguage,
        ),
        Routes.home,
      );
    });
  });

  group('resolveRedirect — role', () {
    test('signed-in user without a complete profile may pick a role', () {
      // The choose-role screen sits between verify and complete-profile.
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: true,
          onboardingSeen: true,
          profileComplete: false,
          location: Routes.chooseRole,
        ),
        isNull,
      );
    });

    test('new signed-in user without a chosen role must choose-role', () {
      // Covers Google OAuth: signed in, profile incomplete, role not yet picked.
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: true,
          onboardingSeen: true,
          profileComplete: false,
          location: Routes.home,
        ),
        Routes.chooseRole,
      );
    });

    test('new user must choose-role before complete-profile', () {
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: true,
          onboardingSeen: true,
          profileComplete: false,
          location: Routes.completeProfile,
        ),
        Routes.chooseRole,
      );
    });

    test('onboarded employer is sent to the employer dashboard from home', () {
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: true,
          onboardingSeen: true,
          profileComplete: true,
          role: UserRole.employer,
          location: Routes.home,
        ),
        Routes.employerDashboard,
      );
    });

    test('onboarded employer can browse the employer area', () {
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: true,
          onboardingSeen: true,
          profileComplete: true,
          role: UserRole.employer,
          location: Routes.employerDashboard,
        ),
        isNull,
      );
    });

    test('onboarded employer is sent to dashboard from auth screens', () {
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: true,
          onboardingSeen: true,
          profileComplete: true,
          role: UserRole.employer,
          location: Routes.signIn,
        ),
        Routes.employerDashboard,
      );
    });

    test('employer setup zone is create-company, not seeker preferences', () {
      // An employer mid-setup landing on a seeker preference page is bounced
      // back to complete-profile.
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: true,
          onboardingSeen: true,
          profileComplete: false,
          role: UserRole.employer,
          roleChosen: true,
          location: Routes.setupJobType,
        ),
        Routes.completeProfile,
      );
    });

    test('employer mid-setup may stay on create-company onboarding', () {
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: true,
          onboardingSeen: true,
          profileComplete: false,
          role: UserRole.employer,
          roleChosen: true,
          location: Routes.employerOnboard,
        ),
        isNull,
      );
    });

    test('job seeker is kept out of the employer area', () {
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: true,
          onboardingSeen: true,
          profileComplete: true,
          location: Routes.employerDashboard,
        ),
        Routes.home,
      );
    });

    test('onboarded employer can reach the shared chat surface', () {
      // Employers message candidates from /chat — they must not be bounced back
      // to the dashboard.
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: true,
          onboardingSeen: true,
          profileComplete: true,
          role: UserRole.employer,
          location: Routes.chatDetail('c1'),
        ),
        isNull,
      );
    });

    test('password reset is reachable for an onboarded seeker', () {
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: true,
          onboardingSeen: true,
          profileComplete: true,
          location: Routes.newPassword,
        ),
        isNull,
      );
    });

    test('password reset is reachable for an onboarded employer', () {
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: true,
          onboardingSeen: true,
          profileComplete: true,
          role: UserRole.employer,
          location: Routes.newPassword,
        ),
        isNull,
      );
    });

    test('password reset is reachable during recovery even with an '
        'incomplete profile (e.g. straight after sign-out)', () {
      expect(
        resolveRedirect(
          hasSupabase: true,
          signedIn: true,
          onboardingSeen: true,
          profileComplete: false,
          roleChosen: false,
          location: Routes.newPassword,
        ),
        isNull,
      );
    });

    test('offline mode never redirects regardless of role', () {
      expect(
        resolveRedirect(
          hasSupabase: false,
          signedIn: false,
          onboardingSeen: false,
          profileComplete: false,
          role: UserRole.employer,
          location: Routes.home,
        ),
        isNull,
      );
    });
  });

  group('UserRole.fromWire', () {
    test('round-trips known wire values', () {
      expect(UserRole.fromWire('job_seeker'), UserRole.jobSeeker);
      expect(UserRole.fromWire('employer'), UserRole.employer);
    });

    test('returns null for unknown or missing values', () {
      expect(UserRole.fromWire('admin'), isNull);
      expect(UserRole.fromWire(null), isNull);
    });
  });
}
