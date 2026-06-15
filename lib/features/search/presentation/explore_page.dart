import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../jobs/presentation/widgets/job_card.dart';
import '../application/search_controller.dart';
import 'widgets/filter_button.dart';

class ExplorePage extends ConsumerWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final colors = context.colors;
    final results = ref.watch(searchControllerProvider);
    final activeCount = ref
        .watch(searchControllerProvider.notifier)
        .filters
        .activeCount;

    return JzScaffold(
      title: l.navExplore,
      showBack: false,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push(Routes.search),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.lg,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            l.search,
                            style: context.text.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilterButton(
                  count: activeCount,
                  onTap: () => context.push(Routes.filter),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: results.when(
              loading: () => const JzLoader(),
              error: (_, _) => Center(child: Text(l.errUnknown)),
              data: (jobs) => jobs.isEmpty
                  ? JzEmptyState(
                      icon: Icons.search_off_rounded,
                      title: l.noResultsTitle,
                      message: l.noResultsBody,
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
    );
  }
}
