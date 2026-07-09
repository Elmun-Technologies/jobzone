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
        // Active paid promotions float to the top, then by recency.
        .order('boost_active', ascending: false)
        .order('posted_at', ascending: !recentFirst)
        .limit(limit);
    return rows.map<Job>((r) => Job.fromMap(r)).toList();
  }

  /// Stable sort that floats boosted jobs to the front (offline ordering).
  List<Job> _boostedFirst(Iterable<Job> jobs) {
    final list = jobs.toList();
    final boosted = [
      for (final j in list)
        if (j.isBoosted) j,
    ];
    final rest = [
      for (final j in list)
        if (!j.isBoosted) j,
    ];
    return [...boosted, ...rest];
  }

  @override
  Future<List<Job>> jobsPage({
    required int offset,
    required int limit,
    bool recentFirst = true,
  }) async {
    if (!_live) {
      final all = _boostedFirst(recentFirst ? mockJobs : mockJobs.reversed);
      return all.skip(offset).take(limit).toList();
    }
    final rows = await _client
        .from('job_feed')
        .select()
        .eq('status', 'open')
        .order('boost_active', ascending: false)
        .order('posted_at', ascending: !recentFirst)
        .range(offset, offset + limit - 1);
    return rows.map<Job>((r) => Job.fromMap(r)).toList();
  }

  @override
  Future<List<Job>> recommended({int limit = 30}) async {
    if (!_live) {
      // Offline demo: stand in with the mock feed (boosted first).
      return _boostedFirst(mockJobs).take(limit).toList();
    }
    // Same shared RPC the web app calls, so both rank identically.
    final rows = (await _client.rpc('recommended_jobs')) as List;
    return rows
        .map<Job>((r) => Job.fromMap(r as Map<String, dynamic>))
        .take(limit)
        .toList();
  }

  @override
  Future<List<Job>> recent({int limit = 10}) async {
    if (!_live) return _boostedFirst(mockJobs).take(limit).toList();
    return _query(limit: limit);
  }

  @override
  Future<List<Job>> suggested({int limit = 10}) async {
    if (!_live) return _boostedFirst(mockJobs.reversed).take(limit).toList();
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

  @override
  Future<List<Job>> byCompany(String companyId, {int limit = 20}) async {
    if (!_live) {
      return _boostedFirst(mockJobs.where((j) => j.companyId == companyId));
    }
    final rows = await _client
        .from('job_feed')
        .select()
        .eq('company_id', companyId)
        .eq('status', 'open')
        .order('boost_active', ascending: false)
        .order('posted_at', ascending: false)
        .limit(limit);
    return rows.map<Job>((r) => Job.fromMap(r)).toList();
  }

  @override
  Future<List<Job>> byCategory(String categoryName, {int limit = 50}) async {
    if (!_live) {
      return _boostedFirst(
        mockJobs.where((j) => j.categoryName == categoryName),
      ).take(limit).toList();
    }
    final rows = await _client
        .from('job_feed')
        .select()
        .eq('status', 'open')
        .eq('category_name', categoryName)
        .order('boost_active', ascending: false)
        .order('posted_at', ascending: false)
        .limit(limit);
    return rows.map<Job>((r) => Job.fromMap(r)).toList();
  }

  @override
  Future<Map<String, int>> categoryCounts() async {
    final counts = <String, int>{};
    if (!_live) {
      for (final j in mockJobs) {
        final c = j.categoryName;
        if (c != null && c.isNotEmpty) counts[c] = (counts[c] ?? 0) + 1;
      }
      return counts;
    }
    // Only the category name is needed, so keep the projection light.
    final rows = await _client
        .from('job_feed')
        .select('category_name')
        .eq('status', 'open')
        .limit(1000);
    for (final r in rows) {
      final c = r['category_name'] as String?;
      if (c != null && c.isNotEmpty) counts[c] = (counts[c] ?? 0) + 1;
    }
    return counts;
  }
}

final jobsRepositoryProvider = Provider<JobsRepository>(
  (ref) => JobsRepositoryImpl(ref),
);
