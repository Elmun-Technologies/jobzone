import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../jobs/application/jobs_providers.dart';
import '../../jobs/domain/job.dart';
import '../../jobs/presentation/widgets/job_card.dart';
import '../../notifications/application/notifications_providers.dart';
import '../../search/presentation/category_results_page.dart';
import 'widgets/collection_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final suggested = ref.watch(suggestedJobsProvider);
    final recent = ref.watch(recentJobsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(suggestedJobsProvider);
          ref.invalidate(recentJobsProvider);
          await ref.read(recentJobsProvider.future);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _HomeHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: l.quickFindTitle),
                  const SizedBox(height: AppSpacing.md),
                  const JobCollectionsRow(),
                  const SizedBox(height: AppSpacing.xl),
                  const _BrowseByCategory(),
                  SectionHeader(
                    title: l.suggestedJobs,
                    actionLabel: l.seeAll,
                    onAction: () => context.push(Routes.suggestedJobs),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 220,
                    child: suggested.when(
                      loading: () => Shimmer(
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 3,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: AppSpacing.md),
                          itemBuilder: (_, _) =>
                              const JobCardSkeleton(width: 300),
                        ),
                      ),
                      error: (_, _) => _ErrorBox(
                        message: l.errUnknown,
                        onRetry: () => ref.invalidate(suggestedJobsProvider),
                      ),
                      data: (jobs) => jobs.isEmpty
                          ? _EmptyBox(message: l.noJobsTitle)
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: jobs.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: AppSpacing.md),
                              itemBuilder: (_, i) =>
                                  JobCard(job: jobs[i], width: 300),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SectionHeader(
                    title: l.recentJobs,
                    actionLabel: l.seeAll,
                    onAction: () => context.push(Routes.recentJobs),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  recent.when(
                    loading: () => const JobListSkeleton(
                      count: 3,
                      padding: EdgeInsets.zero,
                    ),
                    error: (_, _) => _ErrorBox(
                      message: l.errUnknown,
                      onRetry: () => ref.invalidate(recentJobsProvider),
                    ),
                    data: (jobs) => jobs.isEmpty
                        ? _EmptyBox(message: l.noJobsTitle)
                        : _RecentSection(jobs: jobs),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final colors = context.colors;
    final unread = ref.watch(unreadNotificationsCountProvider);
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topPad + AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.locationLabel,
                      style: context.text.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: colors.gold,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Tashkent, Uzbekistan',
                          style: context.text.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _IconSquare(
                color: Colors.white,
                icon: Icons.notifications_none_rounded,
                iconColor: colors.primary,
                showDot: unread > 0,
                onTap: () => context.push(Routes.notifications),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push(Routes.search),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: colors.textSecondary),
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
              const SizedBox(width: AppSpacing.md),
              _IconSquare(
                color: colors.gold,
                icon: Icons.tune_rounded,
                iconColor: colors.onGold,
                onTap: () => context.push(Routes.filter),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconSquare extends StatelessWidget {
  const _IconSquare({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.showDot = false,
  });

  final Color color;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: iconColor),
          ),
          if (showDot)
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: context.colors.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Recent jobs with a horizontal category filter row.
class _RecentSection extends StatefulWidget {
  const _RecentSection({required this.jobs});
  final List<Job> jobs;

  @override
  State<_RecentSection> createState() => _RecentSectionState();
}

class _RecentSectionState extends State<_RecentSection> {
  String _selected = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final categories = <String>{
      for (final j in widget.jobs)
        if (j.categoryName != null && j.categoryName!.isNotEmpty)
          j.categoryName!,
    }.toList();
    final filtered = _selected.isEmpty
        ? widget.jobs
        : widget.jobs.where((j) => j.categoryName == _selected).toList();

    return Column(
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _CategoryChip(
                label: l.categoryAll,
                selected: _selected.isEmpty,
                onTap: () => setState(() => _selected = ''),
              ),
              for (final c in categories)
                _CategoryChip(
                  label: c,
                  selected: _selected == c,
                  onTap: () => setState(() => _selected = c),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final j in filtered)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: JobCard(job: j),
          ),
      ],
    );
  }
}

/// Profi.ru-style "browse by category" strip: cards showing the open-vacancy
/// count per category; tapping opens that category's results. Hidden until the
/// counts load and when there are none.
class _BrowseByCategory extends ConsumerWidget {
  const _BrowseByCategory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cats = ref.watch(categoryCountsProvider).value ?? const [];
    if (cats.isEmpty) return const SizedBox.shrink();
    final top = cats.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l.browseByCategory),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: top.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, i) =>
                _CategoryCountCard(name: top[i].name, count: top[i].count),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _CategoryCountCard extends StatelessWidget {
  const _CategoryCountCard({required this.name, required this.count});
  final String name;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: () => context.push(Routes.categoryResults(name)),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$count',
              style: context.text.titleLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          alignment: Alignment.center,
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

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: context.text.bodyMedium?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }
}
