import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../applications/domain/application.dart';
import '../../../shared/enums/enums.dart';
import '../domain/applicant.dart';
import 'mock_applicants.dart';

// Offline store so status changes persist across navigation without a backend.
final List<Applicant> _offlineStore = [];
bool _seeded = false;

/// Employer-side view of applications: list applicants for a job (or across all
/// of the employer's jobs) and move them through the hiring pipeline. Owner
/// access is granted by the `is_job_owner` RLS helper.
///
/// Status changes **insert a row into `application_status_history`**; the
/// `sync_application_status` trigger denormalizes `applications.current_status`.
/// We never write `current_status` directly — that would bypass the timeline.
class ApplicantsRepository {
  ApplicantsRepository(this._ref);

  final Ref _ref;

  bool get _live => Env.hasSupabase;

  Future<List<Applicant>> allApplicants() async {
    if (!_live) {
      _seedOffline();
      return [..._offlineStore];
    }
    final client = _ref.read(supabaseClientProvider);
    final uid = client.auth.currentUser?.id;
    if (uid == null) return const [];
    final rows = await client
        .from('applications')
        .select(
          'id, current_status, applied_at, cover_letter, answers, '
          'job_id, '
          'jobs!inner(title, screening_questions, company_id, '
          'companies!inner(owner_id)), '
          'profiles_public(full_name, headline, avatar_url)',
        )
        .eq('jobs.companies.owner_id', uid)
        .order('applied_at', ascending: false);
    return (rows as List)
        .map((r) => _fromRow(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<Applicant>> applicantsForJob(String jobId) async {
    if (!_live) {
      _seedOffline();
      return [
        for (final a in _offlineStore)
          if (a.jobId == jobId) a,
      ];
    }
    final client = _ref.read(supabaseClientProvider);
    final rows = await client
        .from('applications')
        .select(
          'id, current_status, applied_at, cover_letter, answers, '
          'job_id, jobs(title, screening_questions), '
          'profiles_public(full_name, headline, avatar_url)',
        )
        .eq('job_id', jobId)
        .order('applied_at', ascending: false);
    return (rows as List)
        .map((r) => _fromRow(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<StatusEvent>> statusHistory(String applicationId) async {
    if (!_live) {
      final i = _offlineStore.indexWhere((a) => a.id == applicationId);
      return i == -1 ? const [] : _offlineStore[i].history;
    }
    final rows = await _ref
        .read(supabaseClientProvider)
        .from('application_status_history')
        .select()
        .eq('application_id', applicationId)
        .order('changed_at');
    return (rows as List)
        .map(
          (r) => StatusEvent(
            status:
                ApplicationStatus.fromWire(r['status'] as String?) ??
                ApplicationStatus.submitted,
            note: r['note'] as String?,
            changedAt:
                DateTime.tryParse('${r['changed_at']}') ?? DateTime.now(),
          ),
        )
        .toList();
  }

  /// Advances an application to [status] by appending to its history; the DB
  /// trigger denormalizes `current_status`.
  Future<void> updateStatus(
    String applicationId,
    ApplicationStatus status, {
    String? note,
  }) async {
    if (!_live) {
      final i = _offlineStore.indexWhere((a) => a.id == applicationId);
      if (i == -1) return;
      final event = StatusEvent(
        status: status,
        note: note,
        changedAt: DateTime.now(),
      );
      _offlineStore[i] = _offlineStore[i].copyWith(
        status: status,
        history: [..._offlineStore[i].history, event],
      );
      return;
    }
    final client = _ref.read(supabaseClientProvider);
    await client.from('application_status_history').insert({
      'application_id': applicationId,
      'status': status.wire,
      'changed_by': client.auth.currentUser?.id,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Applicant _fromRow(Map<String, dynamic> r) {
    final job = r['jobs'] as Map<String, dynamic>?;
    final profile = r['profiles_public'] as Map<String, dynamic>?;
    return Applicant(
      id: r['id'] as String,
      jobId: (r['job_id'] ?? '') as String,
      jobTitle: (job?['title'] ?? '') as String,
      name: (profile?['full_name'] ?? '') as String,
      headline: profile?['headline'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
      status:
          ApplicationStatus.fromWire(r['current_status'] as String?) ??
          ApplicationStatus.submitted,
      appliedAt: DateTime.tryParse('${r['applied_at']}') ?? DateTime.now(),
      coverLetter: r['cover_letter'] as String?,
      screeningQA: _screeningQA(job?['screening_questions'], r['answers']),
    );
  }

  /// Zips a job's screening questions with an application's answers into
  /// display-ready (question, answer) pairs (booleans → 'yes'/'no').
  List<({String question, String answer})> _screeningQA(
    Object? questions,
    Object? answers,
  ) {
    final qs = questions is List ? questions : const [];
    final ans = answers is Map ? answers.cast<String, dynamic>() : const {};
    final out = <({String question, String answer})>[];
    for (final q in qs) {
      if (q is! Map) continue;
      final id = q['id'] as String?;
      if (id == null || !ans.containsKey(id)) continue;
      final v = ans[id];
      final a = v is bool ? (v ? 'yes' : 'no') : '$v';
      if (a.trim().isEmpty) continue;
      out.add((question: (q['label'] ?? '') as String, answer: a));
    }
    return out;
  }

  void _seedOffline() {
    if (_seeded) return;
    _seeded = true;
    _offlineStore.addAll(seedApplicants());
  }
}

final applicantsRepositoryProvider = Provider<ApplicantsRepository>(
  (ref) => ApplicantsRepository(ref),
);

/// All applicants across the employer's jobs (the Applicants inbox tab).
final allApplicantsProvider = FutureProvider<List<Applicant>>(
  (ref) => ref.read(applicantsRepositoryProvider).allApplicants(),
);

/// Applicants for a single job.
final jobApplicantsProvider = FutureProvider.family<List<Applicant>, String>(
  (ref, jobId) =>
      ref.read(applicantsRepositoryProvider).applicantsForJob(jobId),
);
