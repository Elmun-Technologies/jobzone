import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../jobs/domain/job.dart';
import '../../jobs/presentation/widgets/job_card.dart';
import '../data/search_repository.dart';
import '../domain/job_collection.dart';
import 'job_collection_label.dart';

/// Jobs matching a [JobCollection] preset. Decoupled from the text-search
/// controller so opening a collection never disturbs the user's live search.
final collectionJobsProvider = FutureProvider.family<List<Job>, JobCollection>((
  ref,
  collection,
) {
  return ref.read(searchRepositoryProvider).search(collection.preset);
});

/// Titled results list reached by tapping a Home quick-find card.
class CollectionResultsPage extends ConsumerWidget {
  const CollectionResultsPage({super.key, required this.collection});

  final JobCollection collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final jobsAsync = ref.watch(collectionJobsProvider(collection));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: collection.label(context)),
            ),
            Expanded(
              child: jobsAsync.when(
                loading: () => const JobListSkeleton(),
                error: (_, _) => JzErrorState(
                  title: l.errorTitle,
                  message: l.errUnknown,
                  retryLabel: l.retry,
                  onRetry: () =>
                      ref.invalidate(collectionJobsProvider(collection)),
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
