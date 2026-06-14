import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../application/jobs_providers.dart';
import 'widgets/job_card.dart';

enum SeeAllKind { suggested, recent }

class SeeAllJobsPage extends ConsumerWidget {
  const SeeAllJobsPage({super.key, required this.kind});

  final SeeAllKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final isSuggested = kind == SeeAllKind.suggested;
    final jobsAsync = ref.watch(
      isSuggested ? suggestedJobsProvider : recentJobsProvider,
    );

    return JzScaffold(
      title: isSuggested ? l.suggestedJobs : l.recentJobs,
      body: jobsAsync.when(
        loading: () => const JzLoader(),
        error: (_, _) => Center(child: Text(l.errUnknown)),
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
    );
  }
}
