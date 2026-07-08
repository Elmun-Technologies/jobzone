import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../jobs/data/mock_jobs.dart';
import '../../jobs/domain/job.dart';
import '../domain/search_filters.dart';

/// Runs job search against the `job_feed` view (Postgres) when Supabase is
/// configured — the same source the home/category feeds read, so a freshly
/// posted vacancy is searchable immediately and every facet filters reliably
/// without a Meilisearch reindex. Offline it filters [mockJobs] locally.
class SearchRepository {
  SearchRepository(this._ref);

  final Ref _ref;

  // Matches the filter page's salary slider ceiling; at/above it the upper
  // bound means "no maximum", so we skip the filter (mirrors the mock).
  static const int _salaryCeil = 30000000;

  Future<List<Job>> search(SearchFilters filters) async {
    if (Env.hasSupabase) return _searchViaFeed(filters);
    return _filterMock(filters);
  }

  /// Exact number of open vacancies matching [filters] — a HEAD-only count
  /// (no rows fetched) that powers the filter page's live "N vakansiya"
  /// preview. Shares [_applyFilters] with [search] so the previewed count can
  /// never drift from the results it promises.
  Future<int> count(SearchFilters filters) async {
    if (!Env.hasSupabase) return _filterMock(filters).length;
    final q = _applyFilters(
      _ref
          .read(supabaseClientProvider)
          .from('job_feed')
          .count(CountOption.exact)
          .eq('status', 'open'),
      filters,
    );
    return await q;
  }

  Future<List<Job>> _searchViaFeed(SearchFilters f) async {
    final q = _applyFilters(
      _ref
          .read(supabaseClientProvider)
          .from('job_feed')
          .select()
          .eq('status', 'open'),
      f,
    );

    final orderCol = switch (f.sort) {
      SearchSort.newest => 'posted_at',
      SearchSort.salaryHigh => 'salary_max',
      SearchSort.salaryLow => 'salary_min',
    };
    final rows = await q
        // Active paid promotions float to the top, then the chosen sort.
        .order('boost_active', ascending: false)
        .order(orderCol, ascending: f.sort == SearchSort.salaryLow)
        .limit(60);
    return rows.map<Job>((r) => Job.fromMap(r)).toList();
  }

  /// Applies the free-text + facet filters shared by [search] and [count] to a
  /// `job_feed` query builder (the caller has already scoped it to
  /// `status = 'open'`). Generic over the builder's row type so the same logic
  /// serves both the row query (`select`) and the head count (`count`).
  PostgrestFilterBuilder<T> _applyFilters<T>(
    PostgrestFilterBuilder<T> query,
    SearchFilters f,
  ) {
    var q = query;
    final text = f.query.trim();
    if (text.isNotEmpty) {
      // Strip PostgREST filter delimiters so the term can't break out of the
      // or() grammar; a plain substring match across the key text columns.
      final safe = text.replaceAll(RegExp(r'[,%()]'), ' ').trim();
      if (safe.isNotEmpty) {
        q = q.or(
          'title.ilike.%$safe%,company_name.ilike.%$safe%,'
          'category_name.ilike.%$safe%',
        );
      }
    }
    // Job-title facet (chosen in the filter sheet): a job matches if its title
    // contains any selected title. Live search skipped this — only the mock
    // applied it — so the facet did nothing against Supabase.
    if (f.titles.isNotEmpty) {
      final clauses = f.titles
          .map((t) => t.replaceAll(RegExp(r'[,%()]'), ' ').trim())
          .where((t) => t.isNotEmpty)
          .map((t) => 'title.ilike.%$t%')
          .toList();
      if (clauses.isNotEmpty) q = q.or(clauses.join(','));
    }
    if (f.jobTypes.isNotEmpty) q = q.inFilter('job_type', f.jobTypes.toList());
    if (f.experienceLevels.isNotEmpty) {
      q = q.inFilter('experience_level', f.experienceLevels.toList());
    }
    if (f.workingModels.isNotEmpty) {
      q = q.inFilter('working_model', f.workingModels.toList());
    }
    if (f.schedulePatterns.isNotEmpty) {
      q = q.inFilter('schedule_pattern', f.schedulePatterns.toList());
    }
    if (f.formalizations.isNotEmpty) {
      q = q.inFilter('formalization', f.formalizations.toList());
    }
    if (f.salaryPeriods.isNotEmpty) {
      q = q.inFilter('salary_period', f.salaryPeriods.toList());
    }
    if (f.driverLicenses.isNotEmpty) {
      // A job matches if its required licenses overlap the seeker's selection.
      q = q.overlaps('driver_licenses', f.driverLicenses.toList());
    }
    if (f.city != null && f.city!.isNotEmpty) q = q.eq('city', f.city!);
    if (f.womenFriendly) q = q.eq('women_friendly', true);
    if (f.nightShift) q = q.eq('night_shift', true);
    if (f.disabilityFriendly) q = q.eq('disability_friendly', true);
    if (f.salaryMin != null && f.salaryMin! > 0) {
      q = q.gte('salary_max', f.salaryMin!);
    }
    if (f.salaryMax != null && f.salaryMax! < _salaryCeil) {
      q = q.lte('salary_min', f.salaryMax!);
    }
    if (f.postedWithin != null) {
      final cutoff = DateTime.now().toUtc().subtract(
        Duration(days: f.postedWithin!),
      );
      q = q.gte('posted_at', cutoff.toIso8601String());
    }
    return q;
  }

  List<Job> _filterMock(SearchFilters f) {
    final q = f.query.trim().toLowerCase();
    final now = DateTime.now();
    final list = mockJobs.where((j) {
      if (q.isNotEmpty) {
        final haystack = '${j.title} ${j.companyName} ${j.skills.join(' ')}'
            .toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      if (f.jobTypes.isNotEmpty && !f.jobTypes.contains(j.jobType)) {
        return false;
      }
      if (f.experienceLevels.isNotEmpty &&
          !f.experienceLevels.contains(j.experienceLevel)) {
        return false;
      }
      if (f.workingModels.isNotEmpty &&
          !f.workingModels.contains(j.workingModel)) {
        return false;
      }
      if (f.schedulePatterns.isNotEmpty &&
          !f.schedulePatterns.contains(j.schedulePattern)) {
        return false;
      }
      if (f.formalizations.isNotEmpty &&
          !f.formalizations.contains(j.formalization)) {
        return false;
      }
      if (f.salaryPeriods.isNotEmpty &&
          !f.salaryPeriods.contains(j.salaryPeriod)) {
        return false;
      }
      if (f.driverLicenses.isNotEmpty &&
          !f.driverLicenses.any((c) => j.driverLicenses.contains(c))) {
        return false;
      }
      if (f.salaryMin != null &&
          (j.salaryMax ?? j.salaryMin ?? 0) < f.salaryMin!) {
        return false;
      }
      if (f.salaryMax != null &&
          (j.salaryMin ?? j.salaryMax ?? 0) > f.salaryMax!) {
        return false;
      }
      if (f.postedWithin != null) {
        final cutoff = now.subtract(Duration(days: f.postedWithin!));
        if (j.postedAt == null || j.postedAt!.isBefore(cutoff)) return false;
      }
      if (f.titles.isNotEmpty &&
          !f.titles.any(
            (t) => j.title.toLowerCase().contains(t.toLowerCase()),
          )) {
        return false;
      }
      if (f.city != null &&
          f.city!.isNotEmpty &&
          (j.city?.toLowerCase() != f.city!.toLowerCase())) {
        return false;
      }
      if (f.womenFriendly && !j.womenFriendly) return false;
      if (f.nightShift && !j.nightShift) return false;
      if (f.disabilityFriendly && !j.disabilityFriendly) return false;
      return true;
    }).toList();

    switch (f.sort) {
      case SearchSort.newest:
        list.sort(
          (a, b) => (b.postedAt ?? DateTime(2000)).compareTo(
            a.postedAt ?? DateTime(2000),
          ),
        );
      case SearchSort.salaryHigh:
        list.sort((a, b) => (b.salaryMax ?? 0).compareTo(a.salaryMax ?? 0));
      case SearchSort.salaryLow:
        list.sort((a, b) => (a.salaryMin ?? 0).compareTo(b.salaryMin ?? 0));
    }
    return list;
  }
}

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(ref),
);
