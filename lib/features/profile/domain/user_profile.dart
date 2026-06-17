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
