import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/job.dart';
import '../domain/jobs_repository.dart';
import 'mock_jobs.dart';

/// Reads jobs from the `job_feed` view when Supabase is configured; otherwise
/// serves [mockJobs] so the UI is fully demoable offline.
class JobsRepositoryImpl implements JobsRepository {
  JobsRepositoryImpl(this._ref);

  final Ref _ref;

  bool get _live => Env.hasSupabase;
  SupabaseClient get _client => _ref.read(supabaseClientProvider);

  Future<List<Job>> _query({
    required int limit,
    bool recentFirst = true,
  }) async {
    final rows = await _client
        .from('job_feed')
        .select()
        .eq('status', 'open')
        .order('posted_at', ascending: !recentFirst)
        .limit(limit);
    return rows.map<Job>((r) => Job.fromMap(r)).toList();
  }

  @override
  Future<List<Job>> recent({int limit = 10}) async {
    if (!_live) return mockJobs.take(limit).toList();
    return _query(limit: limit);
  }

  @override
  Future<List<Job>> suggested({int limit = 10}) async {
    if (!_live) return mockJobs.reversed.take(limit).toList();
    // A real ranking against user_preferences lands in a later phase.
    return _query(limit: limit, recentFirst: false);
  }

  @override
  Future<Job?> byId(String id) async {
    if (!_live) {
      for (final j in mockJobs) {
        if (j.id == id) return j;
      }
      return null;
    }
    final row = await _client
        .from('job_feed')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Job.fromMap(row);
  }

  @override
  Future<List<Job>> byIds(Iterable<String> ids) async {
    if (ids.isEmpty) return [];
    if (!_live) return mockJobs.where((j) => ids.contains(j.id)).toList();
    final rows = await _client
        .from('job_feed')
        .select()
        .inFilter('id', ids.toList());
    return rows.map<Job>((r) => Job.fromMap(r)).toList();
  }
}

final jobsRepositoryProvider = Provider<JobsRepository>(
  (ref) => JobsRepositoryImpl(ref),
);
