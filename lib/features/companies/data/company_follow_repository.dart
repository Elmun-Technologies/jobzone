import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../jobs/data/jobs_repository_impl.dart';
import '../../jobs/domain/job.dart';
import '../domain/company.dart';
import 'companies_repository.dart';

/// "Подписки" (Obunalar): the companies a seeker follows, and the open jobs
/// from them. Follow state lives in `company_follows` (owner-scoped RLS); the
/// company and job reads reuse the existing repositories, so this works live
/// and offline without duplicating that data.
class CompanyFollowRepository {
  CompanyFollowRepository(this._ref);

  final Ref _ref;

  bool get _live => Env.hasSupabase;

  String? get _uid =>
      _live ? _ref.read(supabaseClientProvider).auth.currentUser?.id : null;

  /// The set of company ids the current user follows.
  Future<Set<String>> followedIds() async {
    if (!_live) return {..._offlineFollows};
    final uid = _uid;
    if (uid == null) return {};
    final rows = await _ref
        .read(supabaseClientProvider)
        .from('company_follows')
        .select('company_id')
        .eq('profile_id', uid);
    return {for (final r in rows as List) r['company_id'] as String};
  }

  Future<bool> isFollowing(String companyId) async {
    if (!_live) return _offlineFollows.contains(companyId);
    final uid = _uid;
    if (uid == null) return false;
    final row = await _ref
        .read(supabaseClientProvider)
        .from('company_follows')
        .select('company_id')
        .eq('profile_id', uid)
        .eq('company_id', companyId)
        .maybeSingle();
    return row != null;
  }

  Future<void> follow(String companyId) async {
    if (!_live) {
      _offlineFollows.add(companyId);
      return;
    }
    final uid = _uid;
    if (uid == null) return;
    // Idempotent: re-following an already-followed company is a no-op.
    await _ref.read(supabaseClientProvider).from('company_follows').upsert({
      'profile_id': uid,
      'company_id': companyId,
    });
  }

  Future<void> unfollow(String companyId) async {
    if (!_live) {
      _offlineFollows.remove(companyId);
      return;
    }
    final uid = _uid;
    if (uid == null) return;
    await _ref
        .read(supabaseClientProvider)
        .from('company_follows')
        .delete()
        .eq('profile_id', uid)
        .eq('company_id', companyId);
  }

  /// Toggles follow state and returns the new value.
  Future<bool> toggle(String companyId) async {
    final following = await isFollowing(companyId);
    if (following) {
      await unfollow(companyId);
    } else {
      await follow(companyId);
    }
    return !following;
  }

  /// The followed companies, resolved through [CompaniesRepository] (so both the
  /// live and offline company data are reused), sorted by name.
  Future<List<Company>> followedCompanies() async {
    final ids = await followedIds();
    if (ids.isEmpty) return const [];
    final repo = _ref.read(companiesRepositoryProvider);
    final companies = <Company>[];
    for (final id in ids) {
      final c = await repo.byId(id);
      if (c != null) companies.add(c);
    }
    companies.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return companies;
  }

  /// Open jobs from every followed company, newest first — the "свежие
  /// вакансии" feed of the subscriptions screen.
  Future<List<Job>> jobsFromFollowed() async {
    final ids = await followedIds();
    if (ids.isEmpty) return const [];
    final repo = _ref.read(jobsRepositoryProvider);
    final jobs = <Job>[];
    for (final id in ids) {
      jobs.addAll(await repo.byCompany(id));
    }
    jobs.sort(
      (a, b) =>
          (b.postedAt ?? DateTime(0)).compareTo(a.postedAt ?? DateTime(0)),
    );
    return jobs;
  }
}

// Offline demo follows (process-wide) — seeded with the sample company so the
// subscriptions screen demos with content when there's no backend.
final Set<String> _offlineFollows = {'c-acme'};

final companyFollowRepositoryProvider = Provider<CompanyFollowRepository>(
  (ref) => CompanyFollowRepository(ref),
);

final isFollowingCompanyProvider = FutureProvider.family<bool, String>(
  (ref, id) => ref.watch(companyFollowRepositoryProvider).isFollowing(id),
);

final followedCompaniesProvider = FutureProvider<List<Company>>(
  (ref) => ref.watch(companyFollowRepositoryProvider).followedCompanies(),
);

final followedCompanyJobsProvider = FutureProvider<List<Job>>(
  (ref) => ref.watch(companyFollowRepositoryProvider).jobsFromFollowed(),
);
