import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/widgets/snackbars.dart';
import '../../jobs/application/jobs_providers.dart';
import '../../jobs/domain/job.dart';
import '../application/applications_controller.dart';

class ApplyJobPage extends ConsumerStatefulWidget {
  const ApplyJobPage({super.key, required this.jobId});
  final String jobId;

  @override
  ConsumerState<ApplyJobPage> createState() => _ApplyJobPageState();
}

class _ApplyJobPageState extends ConsumerState<ApplyJobPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _text = TextEditingController();
  String? _cvName;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickCv() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx'],
    );
    if (res != null && res.files.isNotEmpty) {
      setState(() => _cvName = res.files.first.name);
    }
  }

  Future<void> _submit(Job job) async {
    setState(() => _submitting = true);
    try {
      await ref
          .read(applicationsControllerProvider.notifier)
          .apply(
            job: job,
            coverLetter: _text.text.trim().isEmpty ? null : _text.text.trim(),
          );
      if (mounted) context.go(Routes.applySuccess(widget.jobId));
    } catch (e) {
      if (mounted) showErrorSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final jobAsync = ref.watch(jobByIdProvider(widget.jobId));

    return Scaffold(
      body: SafeArea(
        child: jobAsync.when(
          loading: () => const JzLoader(),
          error: (_, _) => Center(child: Text(l.errUnknown)),
          data: (job) => job == null
              ? JzEmptyState(
                  icon: Icons.search_off_rounded,
                  title: l.noJobsTitle,
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: JzTopBar(title: l.applyTitle),
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
                          JzTextField(
                            label: l.fullName,
                            hint: 'John Doe',
                            controller: _name,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          JzTextField(
                            label: l.email,
                            hint: 'example@gmail.com',
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            l.uploadCvResume,
                            style: context.text.labelLarge,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _UploadBox(fileName: _cvName, onTap: _pickCv),
                          const SizedBox(height: AppSpacing.lg),
                          Text(l.addText, style: context.text.labelLarge),
                          const SizedBox(height: AppSpacing.sm),
                          JzTextField(
                            controller: _text,
                            hint: l.coverLetterHint,
                            maxLines: 6,
                            minLines: 5,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: JzPrimaryButton(
                        label: l.submit,
                        loading: _submitting,
                        onPressed: () => _submit(job),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  const _UploadBox({required this.fileName, required this.onTap});
  final String? fileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Icon(
              IconsaxPlusBold.document_upload,
              color: colors.primary,
              size: 40,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              fileName ?? context.l10n.browseFile,
              style: context.text.bodyMedium?.copyWith(
                color: fileName == null ? colors.textSecondary : colors.primary,
                fontWeight: fileName == null ? null : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
