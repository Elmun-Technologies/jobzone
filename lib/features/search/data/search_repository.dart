import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../jobs/data/mock_jobs.dart';
import '../../jobs/domain/job.dart';
import '../domain/search_filters.dart';

/// Runs job search via the `search-jobs` Edge Function (Meilisearch proxy) when
/// Supabase is configured; otherwise filters [mockJobs] locally so search works
/// offline.
class SearchRepository {
  SearchRepository(this._ref);

  final Ref _ref;

  Future<List<Job>> search(SearchFilters filters) async {
    if (Env.hasSupabase) {
      final res = await _ref
          .read(supabaseClientProvider)
          .functions
          .invoke('search-jobs', body: SearchQuery.from(filters).toJson());
      final data = res.data;
      final hits = (data is Map ? data['hits'] : null) as List? ?? const [];
      return hits
          .map<Job>((h) => Job.fromMap(Map<String, dynamic>.from(h as Map)))
          .toList();
    }
    return _filterMock(filters);
  }

  List<Job> _filterMock(SearchFilters f) {
    final q = f.query.trim().toLowerCase();
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
      if (f.salaryMin != null &&
          (j.salaryMax ?? j.salaryMin ?? 0) < f.salaryMin!) {
        return false;
      }
      if (f.salaryMax != null &&
          (j.salaryMin ?? j.salaryMax ?? 0) > f.salaryMax!) {
        return false;
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
