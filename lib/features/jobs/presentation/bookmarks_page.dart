import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../application/jobs_providers.dart';
import 'widgets/job_card.dart';

class BookmarksPage extends ConsumerWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final jobsAsync = ref.watch(bookmarkedJobsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Text(l.bookmarks, style: context.text.titleLarge),
              ),
            ),
            Expanded(
              child: jobsAsync.when(
                loading: () => const JobListSkeleton(),
                error: (_, _) => JzErrorState(
                  title: l.errorTitle,
                  message: l.errUnknown,
                  retryLabel: l.retry,
                  onRetry: () => ref.invalidate(bookmarkedJobsProvider),
                ),
                data: (jobs) => jobs.isEmpty
                    ? JzEmptyState(
                        icon: Icons.bookmark_border_rounded,
                        title: l.noBookmarksTitle,
                        message: l.noBookmarksBody,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
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
