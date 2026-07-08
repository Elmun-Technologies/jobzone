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

    final jobs = await _ref.read(jobsRepositoryProvider).byIds([
      row['job_id'] as String,
    ]);
    if (jobs.isEmpty) return null;

    return Application(
      id: row['id'] as String,
      job: jobs.first,
      status:
          ApplicationStatus.fromWire(row['current_status'] as String?) ??
          ApplicationStatus.submitted,
      appliedAt: DateTime.tryParse('${row['applied_at']}') ?? DateTime.now(),
      coverLetter: row['cover_letter'] as String?,
    );
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
    if (uid == null) return;
    await _client.from('applications').insert({
      'job_id': job.id,
      'applicant_id': uid,
      'cover_letter': coverLetter,
      'answers': answers ?? <String, dynamic>{},
      'resume_id': ?resumeId,
    });
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
