import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../profile/domain/cv_models.dart';

/// Asks which saved résumé to send, and returns the chosen one (null if the
/// seeker dismissed the sheet).
///
/// One-tap apply used to send nothing at all: `applications.resume_id` was
/// left null even when the seeker had CVs on file, so the employer received an
/// application with no attachment and no way to tell which CV it belonged to.
/// Attaching silently isn't right either once there is more than one — a
/// seeker keeps separate CVs on purpose (driver vs. warehouse, uz vs. ru), and
/// guessing sends the wrong one to a real employer. So: one CV attaches
/// itself, several ask here first.
Future<Resume?> showResumePickSheet(
  BuildContext context,
  List<Resume> resumes,
) {
  return showModalBottomSheet<Resume>(
    context: context,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ResumePickSheet(resumes: resumes),
  );
}

class _ResumePickSheet extends StatelessWidget {
  const _ResumePickSheet({required this.resumes});

  final List<Resume> resumes;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    // Only rows with an id can be attached; a local-only draft has none.
    final items = resumes.where((r) => r.id != null).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l.chooseResumeTitle,
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l.chooseResumeBody,
              style: context.text.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // A long CV list stays scrollable instead of overflowing the sheet.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final r in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _ResumeRow(
                          resume: r,
                          onTap: () => Navigator.of(context).pop(r),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.cancel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeRow extends StatelessWidget {
  const _ResumeRow({required this.resume, required this.onTap});

  final Resume resume;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final size = resume.sizeText;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              Icons.description_outlined,
              color: colors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          resume.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (resume.isDefault) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.chipBackground,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            l.resumeDefaultTag,
                            style: context.text.labelSmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (size != null)
                    Text(
                      size,
                      style: context.text.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
