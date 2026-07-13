import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../jobs/domain/job.dart';
import '../data/search_repository.dart';
import '../domain/search_filters.dart';

/// Holds the current [SearchFilters] and exposes the matching jobs as an
/// [AsyncValue]. Shared by both the Explore and Search screens.
class SearchController extends AsyncNotifier<List<Job>> {
  SearchFilters _filters = const SearchFilters();
  SearchFilters get filters => _filters;

  @override
  Future<List<Job>> build() =>
      ref.read(searchRepositoryProvider).search(_filters);

  Future<void> setQuery(String query) =>
      _update(_filters.copyWith(query: query));

  Future<void> applyFilters(SearchFilters filters) => _update(filters);

  Future<void> reset() => _update(const SearchFilters());

  /// Re-runs the search with the CURRENT filters — unlike
  /// `ref.invalidate(searchControllerProvider)`, which disposes this
  /// notifier and recreates it with `_filters` reset to the default,
  /// silently discarding whatever query/filters the user had applied.
  Future<void> retry() => _update(_filters);

  Future<void> _update(SearchFilters filters) async {
    _filters = filters;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(searchRepositoryProvider).search(_filters),
    );
  }
}

final searchControllerProvider =
    AsyncNotifierProvider<SearchController, List<Job>>(SearchController.new);
