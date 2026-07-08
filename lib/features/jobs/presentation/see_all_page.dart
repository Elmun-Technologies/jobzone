import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../application/paginated_jobs_notifier.dart';
import 'category_label.dart';
import 'widgets/job_card.dart';

enum SeeAllKind { suggested, recent }

class SeeAllJobsPage extends ConsumerStatefulWidget {
  const SeeAllJobsPage({super.key, required this.kind});

  final SeeAllKind kind;

  @override
  ConsumerState<SeeAllJobsPage> createState() => _SeeAllJobsPageState();
}

class _SeeAllJobsPageState extends ConsumerState<SeeAllJobsPage> {
  late final ScrollController _scroll = ScrollController();
  String _category = '';

  bool get _isSuggested => widget.kind == SeeAllKind.suggested;

  // Suggested = not recentFirst; Recent = recentFirst.
  bool get _recentFirst => !_isSuggested;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      ref.read(paginatedJobsProvider(_recentFirst).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = ref.watch(paginatedJobsProvider(_recentFirst));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(
                title: _isSuggested ? l.suggestedJobs : l.recentJobs,
                actions: [
                  JzCircleButton(
                    icon: Icons.search_rounded,
                    onTap: () => context.push(Routes.search),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(context, state, l)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PaginatedJobsState state, dynamic l) {
    // Initial load
    if (state.jobs.isEmpty && state.isLoading) {
      return const JobListSkeleton();
    }

    // Error on first load (no items yet)
    if (state.jobs.isEmpty && state.error != null) {
      return JzErrorState(
        title: l.errorTitle,
        message: l.errUnknown,
        retryLabel: l.retry,
        onRetry: () =>
            ref.read(paginatedJobsProvider(_recentFirst).notifier).refresh(),
      );
    }

    // Genuinely empty
    if (state.jobs.isEmpty) {
      return JzEmptyState(
        icon: Icons.work_outline_rounded,
        title: l.noJobsTitle,
      );
    }

    // Build category list from loaded jobs (Recent Jobs only).
    final categories = !_isSuggested
        ? <String>{
            for (final j in state.jobs)
              if (j.categoryName != null && j.categoryName!.isNotEmpty)
                j.categoryName!,
          }.toList()
        : const <String>[];

    final filtered = _category.isEmpty
        ? state.jobs
        : state.jobs.where((j) => j.categoryName == _category).toList();

    // +1 for the bottom loading indicator when more pages remain.
    final itemCount = filtered.length + (state.hasMore ? 1 : 0);

    return Column(
      children: [
        if (categories.isNotEmpty)
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
                    label: localizedCategory(l, name: c),
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  ),
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            controller: _scroll,
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: itemCount,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) {
              // Last slot → loading spinner or an error retry button.
              if (i == filtered.length) {
                if (state.error != null) {
                  return Center(
                    child: TextButton.icon(
                      onPressed: () => ref
                          .read(paginatedJobsProvider(_recentFirst).notifier)
                          .loadMore(),
                      icon: const Icon(Icons.refresh),
                      label: Text(l.retry),
                    ),
                  );
                }
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: CircularProgressIndicator.adaptive(),
                  ),
                );
              }
              return JobCard(job: filtered[i]);
            },
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
