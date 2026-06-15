import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/enums/enums.dart';
import '../application/applications_controller.dart';
import '../domain/application.dart';
import 'util/status_label.dart';

class MyApplicationsPage extends ConsumerWidget {
  const MyApplicationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(applicationsControllerProvider);
    return JzScaffold(
      title: l.myApplications,
      body: async.when(
        loading: () => const JobListSkeleton(),
        error: (_, _) => JzErrorState(
          title: l.errorTitle,
          message: l.errUnknown,
          retryLabel: l.retry,
          onRetry: () => ref.invalidate(applicationsControllerProvider),
        ),
        data: (apps) => apps.isEmpty
            ? JzEmptyState(
                icon: Icons.description_outlined,
                title: l.noApplicationsTitle,
                message: l.noApplicationsBody,
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: apps.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, i) => _ApplicationCard(application: apps[i]),
              ),
      ),
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
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        applicationStatusLabel(context, status),
        style: context.text.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

String formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application});
  final Application application;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
            Text(application.job.title, style: context.text.titleSmall),
            Text(
              application.job.companyName,
              style: context.text.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                StatusPill(status: application.status),
                const Spacer(),
                Text(
                  formatDate(application.appliedAt),
                  style: context.text.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
