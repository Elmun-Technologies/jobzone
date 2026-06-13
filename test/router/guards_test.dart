import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/app/router/guards.dart';
import 'package:jobzone/app/router/routes.dart';

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
}
