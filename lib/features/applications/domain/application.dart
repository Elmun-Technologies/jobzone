import '../../../shared/enums/enums.dart';
import '../../jobs/domain/job.dart';

/// A single entry in an application's status timeline.
class StatusEvent {
  const StatusEvent({required this.status, this.note, required this.changedAt});

  final ApplicationStatus status;
  final String? note;
  final DateTime changedAt;
}

/// A job application made by the current user.
class Application {
  const Application({
    required this.id,
    required this.job,
    required this.status,
    required this.appliedAt,
    this.coverLetter,
    this.answers = const {},
    this.history = const [],
  });

  final String id;
  final Job job;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final String? coverLetter;

  /// Screening answers keyed by question id (mirrors `applications.answers`).
  final Map<String, dynamic> answers;
  final List<StatusEvent> history;
}
