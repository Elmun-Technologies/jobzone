import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../jobs/data/categories_repository.dart';
import '../../jobs/domain/job.dart';
import '../../jobs/presentation/widgets/job_card.dart';
import '../data/search_repository.dart';
import '../domain/search_filters.dart';

/// Open vacancies grouped by category, with counts and emoji — powers the Home
/// "browse by category" cards. Computed from the open-job feed and sorted by
/// count (desc). One fetch backs both this and [categoryJobsProvider].
final categoryCountsProvider =
    FutureProvider<List<({String name, int count, String emoji})>>((ref) async {
      final jobs = await ref
          .read(searchRepositoryProvider)
          .search(const SearchFilters());
      final nameToEmoji = {
        for (final c in CategoriesRepository.seed) c.name: c.emoji,
      };
      final counts = <String, int>{};
      for (final j in jobs) {
        final c = j.categoryName;
        if (c == null || c.isEmpty) continue;
        counts[c] = (counts[c] ?? 0) + 1;
      }
      final list =
          counts.entries
              .map(
                (e) => (
                  name: e.key,
                  count: e.value,
                  emoji: nameToEmoji[e.key] ?? '🗂️',
                ),
              )
              .toList()
            ..sort((a, b) => b.count.compareTo(a.count));
      return list;
    });

/// Open jobs in a single category (client-side filter over the feed — no
/// search-index/Meili change needed).
final categoryJobsProvider = FutureProvider.family<List<Job>, String>((
  ref,
  name,
) async {
  final jobs = await ref
      .read(searchRepositoryProvider)
      .search(const SearchFilters());
  return jobs.where((j) => j.categoryName == name).toList();
});

/// Titled results list for a category, reached from the Home category cards.
class CategoryResultsPage extends ConsumerWidget {
  const CategoryResultsPage({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final jobsAsync = ref.watch(categoryJobsProvider(category));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: category),
            ),
            Expanded(
              child: jobsAsync.when(
                loading: () => const JobListSkeleton(),
                error: (_, _) => JzErrorState(
                  title: l.errorTitle,
                  message: l.errUnknown,
                  retryLabel: l.retry,
                  onRetry: () => ref.invalidate(categoryJobsProvider(category)),
                ),
                data: (jobs) => jobs.isEmpty
                    ? JzEmptyState(
                        icon: Icons.work_outline_rounded,
                        title: l.noJobsTitle,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: jobs.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (_, i) => JobCard(job: jobs[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
