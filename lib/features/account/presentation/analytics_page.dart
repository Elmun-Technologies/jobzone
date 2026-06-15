import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/enums/enums.dart';
import '../../applications/application/applications_controller.dart';
import '../../applications/presentation/util/status_label.dart';
import '../../jobs/application/bookmarks_controller.dart';

/// Read-only dashboard summarizing the seeker's activity.
class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final apps = ref.watch(applicationsControllerProvider);
    final bookmarks = ref.watch(bookmarksControllerProvider);

    final applications = apps.value ?? const [];
    final activeStatuses = {
      ApplicationStatus.shortlisted,
      ApplicationStatus.interview,
      ApplicationStatus.offer,
    };
    final inProgress = applications
        .where((a) => activeStatuses.contains(a.status))
        .length;
    final saved = bookmarks.value?.length ?? 0;

    return JzScaffold(
      title: l.analytics,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.5,
            children: [
              _StatCard(
                icon: Icons.send_rounded,
                value: '${applications.length}',
                label: l.statApplications,
              ),
              _StatCard(
                icon: Icons.trending_up_rounded,
                value: '$inProgress',
                label: l.statInProgress,
              ),
              _StatCard(
                icon: Icons.visibility_outlined,
                value: '128',
                label: l.statProfileViews,
              ),
              _StatCard(
                icon: Icons.bookmark_border_rounded,
                value: '$saved',
                label: l.statSavedJobs,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l.applicationsByStatus, style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          if (applications.isEmpty)
            Text(
              l.noApplicationsTitle,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            )
          else
            ..._statusBreakdown(context, applications),
        ],
      ),
    );
  }

  List<Widget> _statusBreakdown(BuildContext context, List applications) {
    final total = applications.length;
    final counts = <ApplicationStatus, int>{};
    for (final a in applications) {
      counts[a.status] = (counts[a.status] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final e in entries)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _StatusBar(
            label: applicationStatusLabel(context, e.key),
            color: applicationStatusColor(context, e.key),
            fraction: total == 0 ? 0 : e.value / total,
            count: e.value,
          ),
        ),
    ];
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: colors.primary),
          Text(value, style: context.text.headlineSmall),
          Text(
            label,
            style: context.text.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.label,
    required this.color,
    required this.fraction,
    required this.count,
  });
  final String label;
  final Color color;
  final double fraction;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: context.text.bodyMedium),
            Text('$count', style: context.text.labelLarge),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: context.colors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
