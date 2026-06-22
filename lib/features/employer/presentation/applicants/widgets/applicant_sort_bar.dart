import 'package:flutter/material.dart';

import '../../../../../design_system/design_system.dart';
import '../../../../../localization/l10n_extension.dart';
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

/// Sort toggle (Newest | Nearest) + a "Map" action above the applicant list.
class ApplicantSortBar extends StatelessWidget {
  const ApplicantSortBar({
    super.key,
    required this.sort,
    required this.onSort,
    required this.onMap,
  });

  final ApplicantSort sort;
  final ValueChanged<ApplicantSort> onSort;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Row(
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
