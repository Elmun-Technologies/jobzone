import '../../../shared/enums/enums.dart';

/// Aggregated, read-only view of a user's profile and key CV sections.
class UserProfile {
  const UserProfile({
    this.fullName,
    this.headline,
    this.bio,
    this.avatarUrl,
    this.city,
    this.country,
    this.email,
    this.phone,
    this.isOpenToWork = true,
    this.seekingStatus = SeekingStatus.activelyLooking,
    this.role = UserRole.jobSeeker,
    this.phoneVerified = false,
    this.workerVerified = false,
    this.desiredPayMin,
    this.desiredPayMax,
    this.desiredPayCurrency = 'UZS',
    this.availability,
    this.experiences = const [],
    this.educations = const [],
    this.skills = const [],
  });

  final String? fullName;
  final String? headline;
  final String? bio;
  final String? avatarUrl;
  final String? city;
  final String? country;
  final String? email;
  final String? phone;
  final bool isOpenToWork;
  final SeekingStatus seekingStatus;
  final UserRole role;

  /// Trust signals (admin-granted / phone-OTP; see migration 0016).
  final bool phoneVerified;
  final bool workerVerified;

  /// Blue-collar worker card: desired pay range + availability.
  final num? desiredPayMin;
  final num? desiredPayMax;
  final String desiredPayCurrency;
  final String? availability; // immediate / two_weeks / flexible
  final List<ExperienceEntry> experiences;
  final List<EducationEntry> educations;
  final List<String> skills;

  String get locationText =>
      [city, country].where((e) => e != null && e.isNotEmpty).join(', ');
}

class ExperienceEntry {
  const ExperienceEntry({
    required this.title,
    this.companyName,
    this.period,
    this.description,
  });

  final String title;
  final String? companyName;
  final String? period;
  final String? description;
}

class EducationEntry {
  const EducationEntry({required this.school, this.degree, this.period});

  final String school;
  final String? degree;
  final String? period;
}
