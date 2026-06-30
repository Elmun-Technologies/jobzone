import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/jobs_repository_impl.dart';
import '../domain/job.dart';
import '../domain/jobs_repository.dart';

const _kPageSize = 20;

class PaginatedJobsState {
  const PaginatedJobsState({
    this.jobs = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  final List<Job> jobs;
  final bool isLoading;
  final bool hasMore;
  final Object? error;

  PaginatedJobsState copyWith({
    List<Job>? jobs,
    bool? isLoading,
    bool? hasMore,
    Object? error,
  }) => PaginatedJobsState(
    jobs: jobs ?? this.jobs,
    isLoading: isLoading ?? this.isLoading,
    hasMore: hasMore ?? this.hasMore,
    error: error,
  );
}

/// Infinite-scroll notifier for the "See All" job list.
/// [recentFirst] = true → Recent Jobs order; false → Suggested (relevance) order.
class PaginatedJobsNotifier extends Notifier<PaginatedJobsState> {
  PaginatedJobsNotifier({required this.recentFirst});

  final bool recentFirst;

  JobsRepository get _repo => ref.read(jobsRepositoryProvider);

  @override
  PaginatedJobsState build() {
    // Kick off the first page after the state is set.
    Future.microtask(loadMore);
    return const PaginatedJobsState();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final page = await _repo.jobsPage(
        offset: state.jobs.length,
        limit: _kPageSize,
        recentFirst: recentFirst,
      );
      state = state.copyWith(
        jobs: [...state.jobs, ...page],
        isLoading: false,
        hasMore: page.length == _kPageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> refresh() async {
    state = const PaginatedJobsState();
    await loadMore();
  }
}

/// Family key: `true` = recent-first order; `false` = suggested (relevance) order.
final paginatedJobsProvider =
    NotifierProvider.family<PaginatedJobsNotifier, PaginatedJobsState, bool>(
      (recentFirst) => PaginatedJobsNotifier(recentFirst: recentFirst),
    );
