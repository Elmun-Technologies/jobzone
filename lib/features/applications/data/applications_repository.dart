import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/enums/enums.dart';
import '../../jobs/data/jobs_repository_impl.dart';
import '../../jobs/data/mock_jobs.dart';
import '../../jobs/domain/job.dart';
import '../domain/application.dart';

// Offline-mode store so applications persist across navigation without a backend.
final List<Application> _offlineStore = [];
bool _seeded = false;

/// Thrown by [ApplicationsRepository.apply] when the session has no signed-in
/// user (e.g. expired between page load and submit) — the caller must not
/// treat this as a successful application.
class NotSignedIn implements Exception {
  const NotSignedIn();
}

/// Creates, lists and tracks the current user's job applications. Uses the
/// `applications` table when Supabase is configured; otherwise an in-memory
/// store seeded with a demo application.
class ApplicationsRepository {
  ApplicationsRepository(this._ref);

  final Ref _ref;
  bool get _live => Env.hasSupabase;
  SupabaseClient get _client => _ref.read(supabaseClientProvider);

  Future<List<Application>> myApplications() async {
    if (!_live) {
      _seedOffline();
      return _offlineStore.reversed.toList();
    }
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    final rows = await _client
        .from('applications')
        .select('id, cover_letter, current_status, applied_at, job_id')
        .eq('applicant_id', uid)
        .order('applied_at', ascending: false);

    final jobs = await _ref
        .read(jobsRepositoryProvider)
        .byIds(rows.map((r) => r['job_id'] as String));
    final jobById = {for (final j in jobs) j.id: j};

    // byIds() reads job_feed, which only carries open, unexpired vacancies.
    // Dropping the rows it can't resolve silently deleted an application the
    // moment its job closed or expired — including from the Archive tab, and
    // including for someone who was HIRED for that now-filled position. The
    // web has read `my_applied_jobs` (0048) since it hit the same bug; this
    // brings mobile onto the same view.
    final missing = rows
        .map((r) => r['job_id'] as String)
        .where((id) => !jobById.containsKey(id))
        .toSet();
    if (missing.isNotEmpty) {
      jobById.addAll(await _closedJobsByIds(missing));
    }

    return rows
        .where((r) => jobById.containsKey(r['job_id']))
        .map<Application>(
          (r) => Application(
            id: r['id'] as String,
            job: jobById[r['job_id']]!,
            status:
                ApplicationStatus.fromWire(r['current_status'] as String?) ??
                ApplicationStatus.submitted,
            appliedAt:
                DateTime.tryParse('${r['applied_at']}') ?? DateTime.now(),
            coverLetter: r['cover_letter'] as String?,
          ),
        )
        .toList();
  }

  /// A single application by id, for the deep-link from an "application update"
  /// notification (which carries only the id, no in-memory object). Mirrors
  /// [myApplications]; scoped to the signed-in applicant (RLS also enforces it).
  Future<Application?> byId(String applicationId) async {
    if (!_live) {
      _seedOffline();
      for (final a in _offlineStore) {
        if (a.id == applicationId) return a;
      }
      return null;
    }
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;

    final row = await _client
        .from('applications')
        .select('id, cover_letter, current_status, applied_at, job_id')
        .eq('id', applicationId)
        .eq('applicant_id', uid)
        .maybeSingle();
    if (row == null) return null;

    final jobId = row['job_id'] as String;
    final jobs = await _ref.read(jobsRepositoryProvider).byIds([jobId]);
    // Same closed-job fallback as myApplications: a push notification about an
    // application whose vacancy has since closed must still open its screen.
    final job = jobs.isNotEmpty
        ? jobs.first
        : (await _closedJobsByIds({jobId}))[jobId];
    if (job == null) return null;

    return Application(
      id: row['id'] as String,
      job: job,
      status:
          ApplicationStatus.fromWire(row['current_status'] as String?) ??
          ApplicationStatus.submitted,
      appliedAt: DateTime.tryParse('${row['applied_at']}') ?? DateTime.now(),
      coverLetter: row['cover_letter'] as String?,
    );
  }

  /// Minimal [Job] stand-ins for vacancies that are no longer in `job_feed`
  /// (closed, expired or blocked), read from the `my_applied_jobs` definer
  /// view (0048) — which is scoped to jobs the caller actually applied to, so
  /// this grants no wider visibility than the application row itself.
  ///
  /// The view carries only id/title/status/company_name; that is what the
  /// applications list and the status screen render, and the rest of the Job
  /// falls back to its defaults. A closed job has no live listing to link to
  /// anyway.
  Future<Map<String, Job>> _closedJobsByIds(Set<String> ids) async {
    if (ids.isEmpty) return const {};
    try {
      final rows = await _client
          .from('my_applied_jobs')
          .select('id, title, status, company_name')
          .inFilter('id', ids.toList());
      return {
        for (final r in rows as List)
          (r['id'] as String): Job(
            id: r['id'] as String,
            title: (r['title'] ?? '') as String,
            companyId: '',
            companyName: (r['company_name'] ?? '') as String,
            status: (r['status'] ?? 'closed') as String,
          ),
      };
    } catch (e) {
      // A DB behind on 0048 has no such view. Degrade to the old behaviour
      // (the row is dropped) rather than failing the whole list.
      if (kDebugMode) debugPrint('my_applied_jobs lookup failed: $e');
      return const {};
    }
  }

  Future<void> apply({
    required Job job,
    String? coverLetter,
    Map<String, dynamic>? answers,
    String? resumeId,
  }) async {
    if (!_live) {
      _seedOffline();
      final now = DateTime.now();
      _offlineStore.add(
        Application(
          id: 'local-${now.microsecondsSinceEpoch}',
          job: job,
          status: ApplicationStatus.submitted,
          appliedAt: now,
          coverLetter: coverLetter,
          answers: answers ?? const {},
          history: [
            StatusEvent(status: ApplicationStatus.submitted, changedAt: now),
          ],
        ),
      );
      return;
    }
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const NotSignedIn();
    await _client.from('applications').insert({
      'job_id': job.id,
      'applicant_id': uid,
      'cover_letter': coverLetter,
      'answers': answers ?? <String, dynamic>{},
      'resume_id': ?resumeId,
    });
  }

  /// Withdraws the caller's own application. Applicants can no longer UPDATE
  /// `applications` directly (0027 locked that to the job owner to close the
  /// self-promotion hole), so this calls the `withdraw_application` SECURITY
  /// DEFINER RPC (0059), which only allows the applicant to move their own
  /// row to `withdrawn`.
  Future<void> withdraw(String applicationId) async {
    if (!_live) {
      final idx = _offlineStore.indexWhere((a) => a.id == applicationId);
      if (idx != -1) {
        final a = _offlineStore[idx];
        _offlineStore[idx] = Application(
          id: a.id,
          job: a.job,
          status: ApplicationStatus.withdrawn,
          appliedAt: a.appliedAt,
          coverLetter: a.coverLetter,
          answers: a.answers,
          history: a.history,
        );
      }
      return;
    }
    await _client.rpc(
      'withdraw_application',
      params: {'p_application_id': applicationId},
    );
  }

  Future<List<StatusEvent>> statusHistory(String applicationId) async {
    if (!_live) {
      final idx = _offlineStore.indexWhere((a) => a.id == applicationId);
      return idx == -1 ? const [] : _offlineStore[idx].history;
    }
    final rows = await _client
        .from('application_status_history')
        .select()
        .eq('application_id', applicationId)
        .order('changed_at');
    return rows
        .map<StatusEvent>(
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

  void _seedOffline() {
    if (_seeded) return;
    _seeded = true;
    if (mockJobs.length < 2) return;
    _offlineStore.add(
      Application(
        id: 'local-seed-1',
        job: mockJobs[1],
        status: ApplicationStatus.interview,
        appliedAt: DateTime(2026, 6, 5),
        history: [
          StatusEvent(
            status: ApplicationStatus.submitted,
            changedAt: DateTime(2026, 6, 5),
          ),
          StatusEvent(
            status: ApplicationStatus.viewed,
            changedAt: DateTime(2026, 6, 6),
          ),
          StatusEvent(
            status: ApplicationStatus.shortlisted,
            changedAt: DateTime(2026, 6, 8),
          ),
          StatusEvent(
            status: ApplicationStatus.interview,
            changedAt: DateTime(2026, 6, 10),
          ),
        ],
      ),
    );
  }
}

final applicationsRepositoryProvider = Provider<ApplicationsRepository>(
  (ref) => ApplicationsRepository(ref),
);

/// Loads one application by id — backs the notification deep-link into the
/// status page when no in-memory application was passed.
final applicationByIdProvider = FutureProvider.family<Application?, String>(
  (ref, id) => ref.read(applicationsRepositoryProvider).byId(id),
);
