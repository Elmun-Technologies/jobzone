import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../application/jobs_providers.dart';
import 'widgets/job_card.dart';

/// The jobs a seeker archived ("not interested" — hidden from every feed).
///
/// Archiving was a one-way door: the only "tap to restore" affordance lived
/// on the card that had just been hidden. This is where those jobs live now,
/// reached from the account menu; each [JobCard] already renders its archive
/// toggle pressed (it watches the same dismissed set this list is built
/// from), so tapping it restores the job and the list updates on its own.
class ArchivedJobsPage extends ConsumerWidget {
  const ArchivedJobsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final jobsAsync = ref.watch(archivedJobsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.archivedJobsTitle),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.archivedJobsSubtitle,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: jobsAsync.when(
                loading: () => const JzLoader(),
                error: (_, _) => JzErrorState(
                  title: l.errorTitle,
                  message: l.errUnknown,
                  retryLabel: l.retry,
                  onRetry: () => ref.invalidate(archivedJobsProvider),
                ),
                data: (jobs) => jobs.isEmpty
                    ? JzEmptyState(
                        icon: Icons.archive_outlined,
                        title: l.noArchivedTitle,
                        message: l.noArchivedBody,
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.refresh(archivedJobsProvider.future),
                        child: ListView.separated(
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
            ),
          ],
        ),
      ),
    );
  }
}
