import '../../../core/utils/geo.dart';
import '../../../shared/enums/enums.dart';
import '../../applications/domain/application.dart';

/// An applicant for one of the employer's jobs: the application plus a
/// lightweight snapshot of the candidate, as the employer sees it.
class Applicant {
  const Applicant({
    required this.id,
    required this.jobId,
    this.workerId = '',
    required this.jobTitle,
    required this.name,
    this.headline,
    this.avatarUrl,
    this.skills = const [],
    required this.status,
    required this.appliedAt,
    this.coverLetter,
    this.history = const [],
    this.screeningQA = const [],
    this.lat,
    this.lng,
    this.jobLat,
    this.jobLng,
  });

  /// The application id (used as the key for status updates).
  final String id;
  final String jobId;

  /// The candidate's profile id (`applications.applicant_id`) — for rating them.
  final String workerId;
  final String jobTitle;
  final String name;
  final String? headline;
  final String? avatarUrl;
  final List<String> skills;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final String? coverLetter;
  final List<StatusEvent> history;

  /// Screening Q&A as shown to the employer (question + display-ready answer).
  final List<({String question, String answer})> screeningQA;

  /// Candidate's home coordinates and the job's coordinates (distance origin),
  /// both nullable. Carried on the row so the cross-job inbox can show a
  /// per-applicant distance without re-fetching each job.
  final double? lat;
  final double? lng;
  final double? jobLat;
  final double? jobLng;

  /// Commute distance candidate → job in km, or null if either side has no
  /// location (graceful: such applicants sort last and show no badge).
  double? get distanceKm => geoDistanceKm(lat, lng, jobLat, jobLng);

  Applicant copyWith({ApplicationStatus? status, List<StatusEvent>? history}) =>
      Applicant(
        id: id,
        jobId: jobId,
        workerId: workerId,
        jobTitle: jobTitle,
        name: name,
        headline: headline,
        avatarUrl: avatarUrl,
        skills: skills,
        status: status ?? this.status,
        appliedAt: appliedAt,
        coverLetter: coverLetter,
        history: history ?? this.history,
        screeningQA: screeningQA,
        lat: lat,
        lng: lng,
        jobLat: jobLat,
        jobLng: jobLng,
      );
}
