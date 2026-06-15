import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../jobs/application/jobs_providers.dart';
import '../../jobs/presentation/widgets/job_card.dart';
import '../../notifications/application/notifications_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final colors = context.colors;
    final suggested = ref.watch(suggestedJobsProvider);
    final recent = ref.watch(recentJobsProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(suggestedJobsProvider);
            ref.invalidate(recentJobsProvider);
            await ref.read(recentJobsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.greeting,
                          style: context.text.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        Text(l.findNextJob, style: context.text.titleLarge),
                      ],
                    ),
                  ),
                  Badge.count(
                    count: unread,
                    isLabelVisible: unread > 0,
                    child: IconButton.filledTonal(
                      onPressed: () => context.push(Routes.notifications),
                      icon: const Icon(Icons.notifications_none_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _SearchBar(
                hint: l.search,
                onTap: () => context.push(Routes.search),
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title: l.suggestedJobs,
                actionLabel: l.seeAll,
                onAction: () => context.push(Routes.suggestedJobs),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 190,
                child: suggested.when(
                  loading: () => const Center(child: JzLoader()),
                  error: (_, _) => _ErrorBox(message: l.errUnknown),
                  data: (jobs) => jobs.isEmpty
                      ? _EmptyBox(message: l.noJobsTitle)
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: jobs.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: AppSpacing.md),
                          itemBuilder: (_, i) =>
                              JobCard(job: jobs[i], width: 260),
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
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: JzLoader(),
                ),
                error: (_, _) => _ErrorBox(message: l.errUnknown),
                data: (jobs) => jobs.isEmpty
                    ? _EmptyBox(message: l.noJobsTitle)
                    : Column(
                        children: [
                          for (final j in jobs)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: JobCard(job: j),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.hint, required this.onTap});
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
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
            Icon(Icons.search_rounded, color: colors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              hint,
              style: context.text.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
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
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: context.text.bodyMedium?.copyWith(color: context.colors.danger),
      ),
    );
  }
}
