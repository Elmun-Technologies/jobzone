import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../jobs/application/jobs_providers.dart';
import '../../jobs/presentation/widgets/job_card.dart';
import '../application/recent_searches.dart';
import '../application/search_controller.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _controller;
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _query = ref.read(searchControllerProvider.notifier).filters.query;
    _controller = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(searchControllerProvider.notifier).setQuery(value);
    });
  }

  void _runSearch(String value) {
    _controller.text = value;
    setState(() => _query = value);
    ref.read(recentSearchesProvider.notifier).add(value);
    ref.read(searchControllerProvider.notifier).setQuery(value);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final hasQuery = _query.trim().isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  JzCircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: _onChanged,
                      onSubmitted: _runSearch,
                      decoration: InputDecoration(
                        hintText: l.search,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: l.clear,
                                icon: Icon(Icons.cancel, color: colors.primary),
                                onPressed: () {
                                  _controller.clear();
                                  ref
                                      .read(searchControllerProvider.notifier)
                                      .setQuery('');
                                  setState(() => _query = '');
                                },
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: hasQuery ? _buildResults(context) : _buildRecent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecent(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final recents = ref.watch(recentSearchesProvider);
    final recentJobs = ref.watch(recentJobsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        if (recents.isNotEmpty) ...[
          Text(
            l.recentSearch,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final q in recents)
            InkWell(
              onTap: () => _runSearch(q),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        q,
                        style: context.text.bodyLarge?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          ref.read(recentSearchesProvider.notifier).remove(q),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(
          l.recentView,
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        recentJobs.when(
          loading: () =>
              const JobListSkeleton(count: 3, padding: EdgeInsets.zero),
          error: (_, _) => const SizedBox.shrink(),
          data: (jobs) => Column(
            children: [
              for (final j in jobs)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: JobCard(job: j),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResults(BuildContext context) {
    final l = context.l10n;
    final results = ref.watch(searchControllerProvider);
    return results.when(
      loading: () => const JobListSkeleton(),
      error: (_, _) => JzErrorState(
        title: l.errorTitle,
        message: l.errUnknown,
        retryLabel: l.retry,
        onRetry: () => ref.invalidate(searchControllerProvider),
      ),
      data: (jobs) => jobs.isEmpty
          ? JzEmptyState(
              icon: Icons.search_off_rounded,
              title: l.noResultsTitle,
              message: l.noResultsBody,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              itemCount: jobs.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Text(
                    '${jobs.length} ${l.resultsFound}',
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }
                return JobCard(job: jobs[i - 1]);
              },
            ),
    );
  }
}
