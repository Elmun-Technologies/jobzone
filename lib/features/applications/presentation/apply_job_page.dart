import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/widgets/snackbars.dart';
import '../../jobs/application/jobs_providers.dart';
import '../../jobs/domain/job.dart';
import '../../jobs/domain/screening_question.dart';
import '../../profile/data/cv_repository.dart';
import '../application/applications_controller.dart';

class ApplyJobPage extends ConsumerStatefulWidget {
  const ApplyJobPage({super.key, required this.jobId});
  final String jobId;

  @override
  ConsumerState<ApplyJobPage> createState() => _ApplyJobPageState();
}

class _ApplyJobPageState extends ConsumerState<ApplyJobPage> {
  final _text = TextEditingController();
  final Map<String, dynamic> _answers = {};
  PlatformFile? _cvFile;
  bool _submitting = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickCv() async {
    final res = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx'],
    );
    if (res != null && res.files.isNotEmpty) {
      setState(() => _cvFile = res.files.first);
    }
  }

  Future<void> _submit(Job job) async {
    for (final q in job.screeningQuestions) {
      if (q.required) {
        final a = _answers[q.id];
        if (a == null || (a is String && a.trim().isEmpty)) {
          showErrorSnack(context, context.l10n.answerAllRequired);
          return;
        }
      }
    }
    if (job.requireCoverLetter && _text.text.trim().isEmpty) {
      showErrorSnack(context, context.l10n.valCoverLetterRequired);
      return;
    }
    // When the employer won't accept an incomplete resume, a CV is mandatory.
    if (!job.allowIncompleteResume && _cvFile == null) {
      showErrorSnack(context, context.l10n.resumeRequired);
      return;
    }
    setState(() => _submitting = true);
    try {
      // Actually upload the picked CV and attach it to the application — the
      // earlier version captured only the file name and dropped the file.
      String? resumeId;
      final cv = _cvFile;
      if (cv != null) {
        // file_picker 12: read bytes on demand instead of the deprecated
        // withData/bytes (reads from the path on mobile, the blob on web).
        resumeId = await ref
            .read(cvRepositoryProvider)
            .addResume(
              title: cv.name,
              fileName: cv.name,
              bytes: await cv.readAsBytes(),
              mimeType: _mimeFor(cv.extension),
            );
      }
      await ref
          .read(applicationsControllerProvider.notifier)
          .apply(
            job: job,
            coverLetter: _text.text.trim().isEmpty ? null : _text.text.trim(),
            answers: _answers.isEmpty ? null : _answers,
            resumeId: resumeId,
          );
      if (mounted) context.go(Routes.applySuccess(widget.jobId));
    } on PostgrestException catch (e) {
      // 23505 = unique_violation on (job_id, applicant_id): already applied.
      if (mounted) {
        showErrorSnack(
          context,
          e.code == '23505'
              ? context.l10n.alreadyApplied
              : context.l10n.errUnknown,
        );
      }
    } catch (_) {
      if (mounted) showErrorSnack(context, context.l10n.errUnknown);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _mimeFor(String? ext) => switch (ext?.toLowerCase()) {
    'pdf' => 'application/pdf',
    'doc' => 'application/msword',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    _ => 'application/octet-stream',
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final jobAsync = ref.watch(jobByIdProvider(widget.jobId));

    return Scaffold(
      body: SafeArea(
        child: jobAsync.when(
          loading: () => const JzLoader(),
          error: (_, _) => JzErrorState(
            title: l.errorTitle,
            message: l.errUnknown,
            retryLabel: l.retry,
            onRetry: () => ref.invalidate(jobByIdProvider(widget.jobId)),
          ),
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
                          // Name + email aren't re-collected here: the applicant
                          // is signed in, so the employer already gets their
                          // profile (and the attached CV) via applicant_id. The
                          // old fields were discarded on submit anyway.
                          Text(
                            l.uploadCvResume,
                            style: context.text.labelLarge,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _UploadBox(fileName: _cvFile?.name, onTap: _pickCv),
                          const SizedBox(height: AppSpacing.lg),
                          if (job.screeningQuestions.isNotEmpty) ...[
                            Text(
                              l.screeningSection,
                              style: context.text.labelLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            for (final q in job.screeningQuestions)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.lg,
                                ),
                                child: _ScreeningAnswerField(
                                  question: q,
                                  value: _answers[q.id],
                                  onChanged: (v) =>
                                      setState(() => _answers[q.id] = v),
                                ),
                              ),
                          ],
                          Text(
                            job.requireCoverLetter
                                ? '${l.addText} *'
                                : l.addText,
                            style: context.text.labelLarge,
                          ),
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

/// Renders the input for one screening question by type: yes/no chips for
/// `yesno`, a numeric/text field otherwise. Answers are reported via [onChanged].
class _ScreeningAnswerField extends StatelessWidget {
  const _ScreeningAnswerField({
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final ScreeningQuestion question;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final label = question.required ? '${question.label} *' : question.label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        if (question.type == 'yesno')
          Row(
            children: [
              ChoiceChip(
                label: Text(l.yes),
                selected: value == true,
                onSelected: (_) => onChanged(true),
              ),
              const SizedBox(width: AppSpacing.sm),
              ChoiceChip(
                label: Text(l.no),
                selected: value == false,
                onSelected: (_) => onChanged(false),
              ),
            ],
          )
        // A single-choice question — render the employer's options as chips.
        // Accept both type strings: mobile posts 'multiple_choice', web 'choice'.
        else if ((question.type == 'multiple_choice' ||
                question.type == 'choice') &&
            question.options.isNotEmpty)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final opt in question.options)
                ChoiceChip(
                  label: Text(opt),
                  selected: value == opt,
                  onSelected: (_) => onChanged(opt),
                ),
            ],
          )
        else
          TextFormField(
            initialValue: value is String ? value as String : null,
            keyboardType: question.type == 'number'
                ? TextInputType.number
                : TextInputType.text,
            onChanged: onChanged,
          ),
      ],
    );
  }
}
