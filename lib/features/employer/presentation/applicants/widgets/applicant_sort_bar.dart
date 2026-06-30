import 'package:flutter/material.dart';

import '../../../../../design_system/design_system.dart';
import '../../../../../features/applications/presentation/util/status_label.dart';
import '../../../../../localization/l10n_extension.dart';
import '../../../../../shared/enums/enums.dart';
import '../../../domain/applicant.dart';

/// How the applicant list is ordered.
enum ApplicantSort { newest, nearest }

/// Returns [list] ordered for [sort]. `newest` keeps the repo order
/// (`applied_at` desc); `nearest` sorts by commute distance with unknown
/// distances last so they never crowd out located candidates.
List<Applicant> sortApplicants(List<Applicant> list, ApplicantSort sort) {
  if (sort == ApplicantSort.newest) return list;
  final copy = [...list];
  copy.sort((a, b) {
    final da = a.distanceKm;
    final db = b.distanceKm;
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  });
  return copy;
}

/// Sort toggle (Newest | Nearest) + Map action, plus a scrollable status-filter
/// chip row showing counts per stage. Null [statusFilter] means "show all".
class ApplicantSortBar extends StatelessWidget {
  const ApplicantSortBar({
    super.key,
    required this.sort,
    required this.onSort,
    required this.onMap,
    this.statusCounts = const {},
    this.statusFilter,
    this.onStatusFilter,
  });

  final ApplicantSort sort;
  final ValueChanged<ApplicantSort> onSort;
  final VoidCallback onMap;

  /// Count of applicants per status — drives the chip row badges.
  final Map<ApplicationStatus, int> statusCounts;

  /// Currently active status filter (null = All).
  final ApplicationStatus? statusFilter;
  final ValueChanged<ApplicationStatus?>? onStatusFilter;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;

    final total = statusCounts.values.fold(0, (a, b) => a + b);
    final presentStatuses = ApplicationStatus.values
        .where((s) => (statusCounts[s] ?? 0) > 0)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SortChip(
              label: l.sortNewest,
              selected: sort == ApplicantSort.newest,
              onTap: () => onSort(ApplicantSort.newest),
            ),
            const SizedBox(width: AppSpacing.sm),
            _SortChip(
              label: l.sortNearest,
              selected: sort == ApplicantSort.nearest,
              onTap: () => onSort(ApplicantSort.nearest),
            ),
            const Spacer(),
            InkWell(
              onTap: onMap,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Icon(Icons.map_outlined, size: 18, color: colors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      l.mapView,
                      style: context.text.labelLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (presentStatuses.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatusChip(
                  label: l.filterAll,
                  count: total,
                  selected: statusFilter == null,
                  onTap: () => onStatusFilter?.call(null),
                ),
                for (final s in presentStatuses) ...[
                  const SizedBox(width: AppSpacing.xs),
                  _StatusChip(
                    label: applicationStatusLabel(context, s),
                    count: statusCounts[s] ?? 0,
                    selected: statusFilter == s,
                    activeColor: applicationStatusColor(context, s),
                    onTap: () =>
                        onStatusFilter?.call(statusFilter == s ? null : s),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? colors.primary : colors.border),
        ),
        child: Text(
          label,
          style: context.text.labelLarge?.copyWith(
            color: selected ? colors.onPrimary : colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.activeColor,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = activeColor ?? colors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? color : colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: context.text.labelMedium?.copyWith(
                color: selected ? color : colors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? color : colors.border,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '$count',
                style: context.text.labelSmall?.copyWith(
                  color: selected ? colors.onPrimary : colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
