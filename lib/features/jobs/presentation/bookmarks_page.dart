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

    return JzScaffold(
      title: l.bookmarks,
      body: jobsAsync.when(
        loading: () => const JzLoader(),
        error: (_, _) => Center(child: Text(l.errUnknown)),
        data: (jobs) => jobs.isEmpty
            ? JzEmptyState(
                icon: Icons.bookmark_border_rounded,
                title: l.noBookmarksTitle,
                message: l.noBookmarksBody,
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: jobs.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, i) => JobCard(job: jobs[i]),
              ),
      ),
    );
  }
}
