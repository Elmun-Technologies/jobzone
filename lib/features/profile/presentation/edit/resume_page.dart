import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../application/cv_providers.dart';
import '../../data/cv_repository.dart';
import '../../domain/cv_models.dart';

/// Manage uploaded resumes: upload a PDF, set the default, delete.
class ResumePage extends ConsumerStatefulWidget {
  const ResumePage({super.key});

  @override
  ConsumerState<ResumePage> createState() => _ResumePageState();
}

class _ResumePageState extends ConsumerState<ResumePage> {
  bool _uploading = false;

  Future<void> _upload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx'],
      withData: true,
    );
    final file = result?.files.firstOrNull;
    if (file == null || file.bytes == null) return;

    setState(() => _uploading = true);
    try {
      await ref
          .read(cvRepositoryProvider)
          .addResume(
            title: file.name,
            fileName: file.name,
            bytes: file.bytes!,
            mimeType: file.extension == 'pdf'
                ? 'application/pdf'
                : 'application/octet-stream',
          );
      ref.invalidate(resumesControllerProvider);
      if (mounted) showInfoSnack(context, context.l10n.resumeUploaded);
    } catch (e) {
      if (mounted) showErrorSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _setDefault(Resume r) async {
    if (r.id == null || r.isDefault) return;
    await ref.read(cvRepositoryProvider).setDefaultResume(r.id!);
    ref.invalidate(resumesControllerProvider);
  }

  Future<void> _delete(Resume r) async {
    if (r.id == null) return;
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.deleteEntryTitle),
        content: Text(l.deleteEntryBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(cvRepositoryProvider).deleteResume(r.id!);
      ref.invalidate(resumesControllerProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final async = ref.watch(resumesControllerProvider);

    return JzScaffold(
      title: l.sectionResume,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _upload,
        icon: _uploading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : const Icon(Icons.upload_file_rounded),
        label: Text(l.uploadResume),
      ),
      body: async.when(
        loading: () => const JzLoader(),
        error: (_, _) => Center(child: Text(l.errUnknown)),
        data: (resumes) => resumes.isEmpty
            ? JzEmptyState(
                icon: Icons.description_outlined,
                title: l.noResumeTitle,
                message: l.noResumeBody,
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xxl * 2,
                ),
                itemCount: resumes.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (c, i) => _ResumeTile(
                  resume: resumes[i],
                  onSetDefault: () => _setDefault(resumes[i]),
                  onDelete: () => _delete(resumes[i]),
                ),
              ),
      ),
    );
  }
}

class _ResumeTile extends StatelessWidget {
  const _ResumeTile({
    required this.resume,
    required this.onSetDefault,
    required this.onDelete,
  });

  final Resume resume;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: resume.isDefault ? colors.primary : colors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf_outlined, color: colors.danger),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resume.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall,
                ),
                if (resume.sizeText != null)
                  Text(
                    resume.sizeText!,
                    style: context.text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                if (resume.isDefault)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      l.defaultResume,
                      style: context.text.labelSmall?.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => v == 'default' ? onSetDefault() : onDelete(),
            itemBuilder: (c) => [
              if (!resume.isDefault)
                PopupMenuItem(value: 'default', child: Text(l.setDefault)),
              PopupMenuItem(value: 'delete', child: Text(l.delete)),
            ],
          ),
        ],
      ),
    );
  }
}
