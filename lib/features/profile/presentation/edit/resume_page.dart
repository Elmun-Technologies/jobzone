import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../application/cv_providers.dart';
import '../../data/cv_repository.dart';
import '../../domain/cv_models.dart';

/// Upload Resume/CV editor (Figma): an upload box + the uploaded files, with a
/// sticky Save.
class ResumePage extends ConsumerStatefulWidget {
  const ResumePage({super.key});

  @override
  ConsumerState<ResumePage> createState() => _ResumePageState();
}

class _ResumePageState extends ConsumerState<ResumePage> {
  bool _uploading = false;

  Future<void> _upload() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx'],
    );
    final file = result?.files.firstOrNull;
    if (file == null) return;
    // file_picker 12: read bytes on demand (from the path on mobile, the blob
    // on web) rather than the deprecated withData/bytes.
    final bytes = await file.readAsBytes();

    setState(() => _uploading = true);
    try {
      await ref
          .read(cvRepositoryProvider)
          .addResume(
            title: file.name,
            fileName: file.name,
            bytes: bytes,
            mimeType: file.extension == 'pdf'
                ? 'application/pdf'
                : 'application/octet-stream',
          );
      ref.invalidate(resumesControllerProvider);
      if (mounted) showInfoSnack(context, context.l10n.resumeUploaded);
    } catch (e) {
      if (mounted) showErrorSnack(context, localizedError(context, e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _delete(Resume r) async {
    if (r.id == null) return;
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.confirmRemoveTitle),
        content: Text(r.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(cvRepositoryProvider).deleteResume(r.id!);
      ref.invalidate(resumesControllerProvider);
    } catch (e) {
      if (mounted) showErrorSnack(context, localizedError(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final async = ref.watch(resumesControllerProvider);
    final resumes = async.value ?? const [];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.sectionResume),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  Text(l.uploadResume, style: context.text.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  _UploadBox(uploading: _uploading, onTap: _upload),
                  const SizedBox(height: AppSpacing.lg),
                  for (final r in resumes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ResumeRow(resume: r, onDelete: () => _delete(r)),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: JzPrimaryButton(
                  label: l.save,
                  onPressed: () => context.pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  const _UploadBox({required this.uploading, required this.onTap});
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            if (uploading)
              const SizedBox(
                height: 40,
                width: 40,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            else
              Icon(
                IconsaxPlusBold.document_upload,
                color: colors.primary,
                size: 40,
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.browseFile,
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

class _ResumeRow extends StatelessWidget {
  const _ResumeRow({required this.resume, required this.onDelete});
  final Resume resume;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf_rounded, color: colors.danger, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resume.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (resume.sizeText != null)
                  Text(
                    resume.sizeText!,
                    style: context.text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.l10n.delete,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: colors.textSecondary,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
