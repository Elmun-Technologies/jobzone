import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../jobs/presentation/widgets/job_card.dart';
import '../application/search_controller.dart';
import 'widgets/filter_button.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(searchControllerProvider.notifier).filters.query,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(searchControllerProvider.notifier).setQuery(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final results = ref.watch(searchControllerProvider);
    final activeCount = ref
        .watch(searchControllerProvider.notifier)
        .filters
        .activeCount;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          decoration: InputDecoration(
            hintText: l.search,
            border: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterButton(
              count: activeCount,
              onTap: () => context.push(Routes.filter),
            ),
          ),
        ],
      ),
      body: results.when(
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
