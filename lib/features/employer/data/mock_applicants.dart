import '../../../shared/enums/enums.dart';
import '../../applications/domain/application.dart';
import '../domain/applicant.dart';

/// Offline seed of applicants for the c-acme mock jobs, so the employer's
/// Applicants screens are demoable without a backend. `mock-1` / `mock-3` /
/// `mock-5` are the c-acme jobs from `mock_jobs.dart`.
List<Applicant> seedApplicants() => [
  Applicant(
    id: 'app-1',
    jobId: 'mock-1',
    workerId: 'u-madina',
    jobTitle: 'Senior Flutter Engineer',
    name: 'Madina Karimova',
    headline: 'Senior Mobile Engineer · 6y',
    skills: const ['Flutter', 'Dart', 'Riverpod', 'CI/CD'],
    status: ApplicationStatus.submitted,
    appliedAt: DateTime(2026, 6, 12),
    coverLetter:
        'I have shipped several Flutter apps at scale and would love to '
        'bring that experience to your team.',
    history: [
      StatusEvent(
        status: ApplicationStatus.submitted,
        changedAt: DateTime(2026, 6, 12),
      ),
    ],
    screeningQA: const [
      (question: 'Years of Flutter experience?', answer: '6'),
      (question: 'Are you comfortable working fully remote?', answer: 'yes'),
    ],
  ),
  Applicant(
    id: 'app-2',
    jobId: 'mock-1',
    workerId: 'u-bekzod',
    jobTitle: 'Senior Flutter Engineer',
    name: 'Bekzod Aliyev',
    headline: 'Flutter Developer · 4y',
    skills: const ['Flutter', 'Firebase', 'REST'],
    status: ApplicationStatus.shortlisted,
    appliedAt: DateTime(2026, 6, 11),
    history: [
      StatusEvent(
        status: ApplicationStatus.submitted,
        changedAt: DateTime(2026, 6, 11),
      ),
      StatusEvent(
        status: ApplicationStatus.viewed,
        changedAt: DateTime(2026, 6, 12),
      ),
      StatusEvent(
        status: ApplicationStatus.shortlisted,
        changedAt: DateTime(2026, 6, 13),
      ),
    ],
  ),
  Applicant(
    id: 'app-3',
    jobId: 'mock-3',
    workerId: 'u-nodira',
    jobTitle: 'Backend Developer (Node.js)',
    name: 'Nodira Yusupova',
    headline: 'Backend Engineer · 5y',
    skills: const ['Node.js', 'PostgreSQL', 'AWS'],
    status: ApplicationStatus.interview,
    appliedAt: DateTime(2026, 6, 9),
    history: [
      StatusEvent(
        status: ApplicationStatus.submitted,
        changedAt: DateTime(2026, 6, 9),
      ),
      StatusEvent(
        status: ApplicationStatus.interview,
        changedAt: DateTime(2026, 6, 13),
      ),
    ],
  ),
  Applicant(
    id: 'app-4',
    jobId: 'mock-5',
    workerId: 'u-jasur',
    jobTitle: 'Flutter Intern',
    name: 'Jasur Toshmatov',
    headline: 'CS Student · Flutter enthusiast',
    skills: const ['Dart', 'Flutter'],
    status: ApplicationStatus.submitted,
    appliedAt: DateTime(2026, 6, 14),
    history: [
      StatusEvent(
        status: ApplicationStatus.submitted,
        changedAt: DateTime(2026, 6, 14),
      ),
    ],
  ),
];
