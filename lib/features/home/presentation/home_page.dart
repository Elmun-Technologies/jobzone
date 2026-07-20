import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/utils/uz_geo.dart';
import '../../../shared/widgets/jz_map/jz_map.dart';
import '../../jobs/application/jobs_providers.dart';
import '../../jobs/domain/job.dart';
import '../../jobs/presentation/category_label.dart';
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
          ref.invalidate(recommendedJobsProvider);
          await ref.read(recentJobsProvider.future);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Staggered entrance: header → map → sections. One-shot (Home
            // lives in the shell's IndexedStack, so it plays once per launch).
            const JzFadeSlideIn(dy: 10, child: _HomeHeader()),
            JzFadeSlideIn(
              delay: const Duration(milliseconds: 90),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  0,
                ),
                child: _HomeMapPreview(),
              ),
            ),
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
                  const _RecommendedForYou(),
                  SectionHeader(
                    title: l.suggestedJobs,
                    actionLabel: l.seeAll,
                    onAction: () => context.push(Routes.suggestedJobs),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  suggested.when(
                    loading: () => SizedBox(
                      height: 220,
                      child: Shimmer(
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 3,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: AppSpacing.md),
                          itemBuilder: (_, _) =>
                              const JobCardSkeleton(width: 300),
                        ),
                      ),
                    ),
                    error: (_, _) => SizedBox(
                      height: 220,
                      child: _ErrorBox(
                        message: l.errUnknown,
                        onRetry: () => ref.invalidate(suggestedJobsProvider),
                      ),
                    ),
                    data: (jobs) => jobs.isEmpty
                        ? SizedBox(
                            height: 220,
                            child: _EmptyBox(message: l.noJobsTitle),
                          )
                        : JobCardCarousel(jobs: jobs),
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
                        Flexible(
                          child: Text(
                            context.l10n.homeLocationDefault,
                            style: context.text.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Chevron removed: it implied a location switcher that
                        // didn't exist (no handler). Restore it only when a real
                        // city picker is wired.
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
              // A soft pulse pulls the eye to unread notifications.
              child: JzPulse(
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
            ),
        ],
      ),
    );
  }
}

/// The map-first home centrepiece (mirrors the web homepage's "Map — the
/// centrepiece" section, right after the hero): a non-interactive preview —
/// wrapped in [IgnorePointer] so it can't steal the outer list's scroll
/// gesture — built from the jobs Home already loaded (no extra fetch), tap
/// anywhere to open the full interactive Explore tab. A seeker who wants the
/// plain list can just keep scrolling past it to the sections below.
class _HomeMapPreview extends ConsumerWidget {
  const _HomeMapPreview();

  static const _tashkent = LatLng(41.3111, 69.2797);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final colors = context.colors;
    final jobs = ref.watch(recentJobsProvider).value ?? const <Job>[];
    final markers = [
      // Every job gets a pin — pinless postings fall back to their city
      // centroid so they still show on the preview map (matches Explore + web).
      for (final j in jobs)
        JzMapMarker(
          id: j.id,
          point: jobLatLng(lat: j.lat, lng: j.lng, city: j.city, id: j.id),
          label: j.salaryPillText ?? l.mapSalaryNegotiable,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l.mapPreviewTitle,
          actionLabel: l.openFullMap,
          onAction: () => context.go(Routes.explore),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l.mapPreviewSubtitle,
          style: context.text.bodySmall?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () => context.go(Routes.explore),
            child: SizedBox(
              height: 200,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  IgnorePointer(
                    child: JzMapView(
                      initialCenter: markers.isNotEmpty
                          ? markers.first.point
                          : _tashkent,
                      initialZoom: 11,
                      markers: markers,
                      cluster: true,
                    ),
                  ),
                  // A transparent scrim keeps the "tap to open" affordance
                  // discoverable without hiding the pins underneath.
                  Positioned(
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map_rounded,
                            size: 16,
                            color: colors.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            l.openFullMap,
                            style: context.text.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
                  label: localizedCategory(l, name: c),
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

/// Personalized "Recommended for you" strip — open jobs matched to the seeker's
/// résumé by the shared `recommended_jobs` RPC (identical ranking to web).
/// Hidden until it has matches, so a seeker with no résumé just sees the normal
/// feed.
class _RecommendedForYou extends ConsumerWidget {
  const _RecommendedForYou();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final jobs = ref.watch(recommendedJobsProvider).value ?? const <Job>[];
    if (jobs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l.recommendedForYou),
        const SizedBox(height: AppSpacing.md),
        JobCardCarousel(jobs: jobs),
        const SizedBox(height: AppSpacing.xl),
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
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: top.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, i) => _CategoryCountCard(
              name: top[i].name,
              count: top[i].count,
              emoji: top[i].emoji,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _CategoryCountCard extends StatelessWidget {
  const _CategoryCountCard({
    required this.name,
    required this.count,
    required this.emoji,
  });
  final String name;
  final int count;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 150,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(Routes.categoryResults(name)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Emoji in a volt-tint tile — a small brand accent per category.
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.gold.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizedCategory(context.l10n, name: name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$count',
                      style: context.text.titleSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
