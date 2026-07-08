import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../jobs/data/categories_repository.dart';
import '../../jobs/data/jobs_repository_impl.dart';
import '../../jobs/domain/job.dart';
import '../../jobs/presentation/category_label.dart';
import '../../jobs/presentation/widgets/job_card.dart';

/// Open vacancies grouped by category, with counts and emoji — powers the Home
/// "browse by category" cards. Computed from the open-job feed and sorted by
/// count (desc). One fetch backs both this and [categoryJobsProvider].
final categoryCountsProvider =
    FutureProvider<List<({String name, int count, String emoji})>>((ref) async {
      final counts = await ref.read(jobsRepositoryProvider).categoryCounts();
      final nameToEmoji = {
        for (final c in CategoriesRepository.seed) c.name: c.emoji,
      };
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

/// Open jobs in a single category, read straight from the `job_feed` view so a
/// freshly-posted vacancy shows up in its category immediately — no Meili
/// reindex, matching how the web app reads the same feed.
final categoryJobsProvider = FutureProvider.family<List<Job>, String>((
  ref,
  name,
) async {
  return ref.read(jobsRepositoryProvider).byCategory(name);
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
              child: JzTopBar(title: localizedCategory(l, name: category)),
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
