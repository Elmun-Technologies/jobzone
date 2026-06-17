import '../../../shared/enums/enums.dart';
import '../../applications/domain/application.dart';

/// An applicant for one of the employer's jobs: the application plus a
/// lightweight snapshot of the candidate, as the employer sees it.
class Applicant {
  const Applicant({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.name,
    this.headline,
    this.avatarUrl,
    this.skills = const [],
    required this.status,
    required this.appliedAt,
    this.coverLetter,
    this.history = const [],
  });

  /// The application id (used as the key for status updates).
  final String id;
  final String jobId;
  final String jobTitle;
  final String name;
  final String? headline;
  final String? avatarUrl;
  final List<String> skills;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final String? coverLetter;
  final List<StatusEvent> history;

  Applicant copyWith({ApplicationStatus? status, List<StatusEvent>? history}) =>
      Applicant(
        id: id,
        jobId: jobId,
        jobTitle: jobTitle,
        name: name,
        headline: headline,
        avatarUrl: avatarUrl,
        skills: skills,
        status: status ?? this.status,
        appliedAt: appliedAt,
        coverLetter: coverLetter,
        history: history ?? this.history,
      );
}
