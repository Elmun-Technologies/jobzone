import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../domain/job.dart';
import '../util/job_labels.dart';

/// Confirmation bottom sheet shown before removing a bookmark. Returns true
/// when the user confirms removal.
Future<bool?> showRemoveBookmarkSheet(BuildContext context, Job job) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _RemoveBookmarkSheet(job: job),
  );
}

class _RemoveBookmarkSheet extends StatelessWidget {
  const _RemoveBookmarkSheet({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.removeBookmarkTitle,
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Preview(job: job),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l.cancel),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: JzPrimaryButton(
                    label: l.yesRemove,
                    onPressed: () => Navigator.of(context).pop(true),
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

class _Preview extends StatelessWidget {
  const _Preview({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tags = [
      ?jobTypeLabel(context, job.jobType),
      ?workingModelLabel(context, job.workingModel),
      ?experienceLabel(context, job.experienceLevel),
    ];
    final letter = job.companyName.isEmpty
        ? '?'
        : job.companyName.substring(0, 1).toUpperCase();
    return Container(
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
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  height: 44,
                  width: 44,
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
                      style: context.text.titleSmall?.copyWith(
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          if (job.salaryText != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(color: colors.border, height: 1),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text.rich(
                TextSpan(
                  text: job.salaryText,
                  style: context.text.titleSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                  children: [
                    if (salaryPeriodLabel(context, job.salaryPeriod) != null)
                      TextSpan(
                        text:
                            ' ${salaryPeriodLabel(context, job.salaryPeriod)}',
                        style: context.text.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
