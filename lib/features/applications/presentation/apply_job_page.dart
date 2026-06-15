import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  final _cover = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _cover.dispose();
    super.dispose();
  }

  Future<void> _submit(Job job) async {
    setState(() => _submitting = true);
    try {
      await ref
          .read(applicationsControllerProvider.notifier)
          .apply(
            job: job,
            coverLetter: _cover.text.trim().isEmpty ? null : _cover.text.trim(),
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
    final colors = context.colors;
    final jobAsync = ref.watch(jobByIdProvider(widget.jobId));

    return JzScaffold(
      title: l.applyTitle,
      body: jobAsync.when(
        loading: () => const JzLoader(),
        error: (_, _) => Center(child: Text(l.errUnknown)),
        data: (job) => job == null
            ? JzEmptyState(icon: Icons.search_off_rounded, title: l.noJobsTitle)
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(job.title, style: context.text.titleMedium),
                  Text(
                    [
                      job.companyName,
                      if (job.locationText.isNotEmpty) job.locationText,
                    ].join(' • '),
                    style: context.text.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.description_outlined, color: colors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            l.defaultCv,
                            style: context.text.bodyMedium,
                          ),
                        ),
                        Icon(
                          Icons.check_circle_rounded,
                          color: colors.success,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(l.coverLetter, style: context.text.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _cover,
                    maxLines: 6,
                    decoration: InputDecoration(hintText: l.coverLetterHint),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  JzPrimaryButton(
                    label: l.submitApplication,
                    loading: _submitting,
                    onPressed: () => _submit(job),
                  ),
                ],
              ),
      ),
    );
  }
}
