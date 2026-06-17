import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../application/jobs_providers.dart';
import '../domain/job.dart';
import 'widgets/job_card.dart';

enum SeeAllKind { suggested, recent }

class SeeAllJobsPage extends ConsumerStatefulWidget {
  const SeeAllJobsPage({super.key, required this.kind});

  final SeeAllKind kind;

  @override
  ConsumerState<SeeAllJobsPage> createState() => _SeeAllJobsPageState();
}

class _SeeAllJobsPageState extends ConsumerState<SeeAllJobsPage> {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isSuggested = widget.kind == SeeAllKind.suggested;
    final jobsAsync = ref.watch(
      isSuggested ? suggestedJobsProvider : recentJobsProvider,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(
                title: isSuggested ? l.suggestedJobs : l.recentJobs,
                actions: [
                  JzCircleButton(
                    icon: Icons.search_rounded,
                    onTap: () => context.push(Routes.search),
                  ),
                ],
              ),
            ),
            Expanded(
              child: jobsAsync.when(
                loading: () => const JobListSkeleton(),
                error: (_, _) => JzErrorState(
                  title: l.errorTitle,
                  message: l.errUnknown,
                  retryLabel: l.retry,
                  onRetry: () => ref.invalidate(
                    isSuggested ? suggestedJobsProvider : recentJobsProvider,
                  ),
                ),
                data: (jobs) => jobs.isEmpty
                    ? JzEmptyState(
                        icon: Icons.work_outline_rounded,
                        title: l.noJobsTitle,
                      )
                    : _List(jobs: jobs, showCategories: !isSuggested),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _List extends StatefulWidget {
  const _List({required this.jobs, required this.showCategories});
  final List<Job> jobs;
  final bool showCategories;

  @override
  State<_List> createState() => _ListState();
}

class _ListState extends State<_List> {
  String _category = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final categories = <String>{
      for (final j in widget.jobs)
        if (j.categoryName != null && j.categoryName!.isNotEmpty)
          j.categoryName!,
    }.toList();
    final filtered = _category.isEmpty
        ? widget.jobs
        : widget.jobs.where((j) => j.categoryName == _category).toList();

    return Column(
      children: [
        if (widget.showCategories && categories.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                _CategoryChip(
                  label: l.categoryAll,
                  selected: _category.isEmpty,
                  onTap: () => setState(() => _category = ''),
                ),
                for (final c in categories)
                  _CategoryChip(
                    label: c,
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  ),
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) => JobCard(job: filtered[i]),
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
            ),
          ),
          child: Text(
            label,
            style: context.text.labelLarge?.copyWith(
              color: selected ? colors.onPrimary : colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
