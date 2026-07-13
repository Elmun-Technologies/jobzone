import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/enums/enums.dart';
import '../../jobs/presentation/util/job_labels.dart';
import '../application/applications_controller.dart';
import '../domain/application.dart';
import 'util/status_label.dart';

class MyApplicationsPage extends ConsumerWidget {
  const MyApplicationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(applicationsControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(
                title: l.myApplications,
                actions: [
                  JzCircleButton(
                    icon: Icons.search_rounded,
                    onTap: () => context.push(Routes.search),
                  ),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const JobListSkeleton(),
                error: (_, _) => JzErrorState(
                  title: l.errorTitle,
                  message: l.errUnknown,
                  retryLabel: l.retry,
                  onRetry: () => ref.invalidate(applicationsControllerProvider),
                ),
                data: (apps) => _TabbedApplications(apps: apps),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Applications grouped into SuperJob-style tabs: Actual (live), Invitations
/// (employer moved you forward), Under review (shortlisted), and Archive
/// (final outcomes). Grouping is client-side over the single fetched list.
class _TabbedApplications extends StatelessWidget {
  const _TabbedApplications({required this.apps});
  final List<Application> apps;

  static const _actual = {
    ApplicationStatus.submitted,
    ApplicationStatus.viewed,
  };
  static const _invitations = {
    ApplicationStatus.interview,
    ApplicationStatus.offer,
  };
  static const _underReview = {ApplicationStatus.shortlisted};
  static const _archive = {
    ApplicationStatus.rejected,
    ApplicationStatus.hired,
    ApplicationStatus.withdrawn,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    List<Application> pick(Set<ApplicationStatus> s) =>
        apps.where((a) => s.contains(a.status)).toList();

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: colors.primary,
            unselectedLabelColor: colors.textSecondary,
            indicatorColor: colors.primary,
            dividerColor: colors.border,
            tabs: [
              Tab(text: l.appTabActual),
              Tab(text: l.appTabInvitations),
              Tab(text: l.appTabReview),
              Tab(text: l.appTabArchive),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ApplicationList(apps: pick(_actual)),
                _ApplicationList(apps: pick(_invitations)),
                _ApplicationList(apps: pick(_underReview)),
                _ApplicationList(apps: pick(_archive)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One tab's list of applications, or an empty state when the group is empty.
class _ApplicationList extends StatelessWidget {
  const _ApplicationList({required this.apps});
  final List<Application> apps;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (apps.isEmpty) {
      return JzEmptyState(
        icon: Icons.description_outlined,
        title: l.noApplicationsTitle,
        message: l.noApplicationsBody,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: apps.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) => _ApplicationCard(application: apps[i]),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});
  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final color = applicationStatusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        applicationStatusLabel(context, status),
        style: context.text.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application});
  final Application application;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final job = application.job;
    final tags = [
      ?jobTypeLabel(context, job.jobType),
      ?workingModelLabel(context, job.workingModel),
      ?experienceLabel(context, job.experienceLevel),
    ];
    final letter = job.companyName.isEmpty
        ? '?'
        : job.companyName.substring(0, 1).toUpperCase();

    return GestureDetector(
      onTap: () => context.push(
        Routes.applicationStatus(application.id),
        extra: application,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    width: 44,
                    height: 44,
                    color: colors.primary,
                    alignment: Alignment.center,
                    child: Text(
                      letter,
                      style: context.text.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        job.companyName,
                        style: context.text.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                StatusPill(status: application.status),
              ],
            ),
            if (job.locationText.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: colors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    job.locationText,
                    style: context.text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            if (tags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final t in tags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(t, style: context.text.labelSmall),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
