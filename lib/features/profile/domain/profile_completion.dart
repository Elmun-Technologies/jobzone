import 'user_profile.dart';

/// Single source of truth for "how complete is this profile?"
///
/// Profile hub and Your Profile used to compute two different fractions
/// (8 vs 10 flags), so the same seeker saw "75%" on one screen and "6/10"
/// on the next. Both now call [score] / [total].
abstract final class ProfileCompletion {
  static const int total = 8;

  static int filled(UserProfile? p) {
    if (p == null) return 0;
    final flags = [
      p.fullName?.isNotEmpty ?? false,
      p.bio?.isNotEmpty ?? false,
      p.phone?.isNotEmpty ?? false,
      p.email?.isNotEmpty ?? false,
      p.locationText.isNotEmpty,
      p.experiences.isNotEmpty,
      p.educations.isNotEmpty,
      p.skills.isNotEmpty,
    ];
    return flags.where((b) => b).length;
  }

  static double ratio(UserProfile? p) => filled(p) / total;
}
