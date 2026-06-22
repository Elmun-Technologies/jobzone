import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/enums/enums.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../../applications/domain/application.dart';
import '../../../applications/presentation/util/status_label.dart';
import '../../../chat/domain/chat_models.dart';
import '../../data/applicants_repository.dart';
import '../../domain/applicant.dart';

/// Candidate detail with the hiring-pipeline status timeline and an action to
/// move the applicant to the next stage.
class ApplicantDetailPage extends ConsumerStatefulWidget {
  const ApplicantDetailPage({super.key, required this.applicant});

  final Applicant applicant;

  @override
  ConsumerState<ApplicantDetailPage> createState() =>
      _ApplicantDetailPageState();
}

class _ApplicantDetailPageState extends ConsumerState<ApplicantDetailPage> {
  late Applicant _applicant = widget.applicant;

  Future<void> _pickStatus() async {
    final l = context.l10n;
    final picked = await showModalBottomSheet<ApplicationStatus>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l.updateStatusCta,
                style: c.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final s in ApplicationStatus.values)
              ListTile(
                title: Text(applicationStatusLabel(c, s)),
                trailing: _applicant.status == s
                    ? Icon(Icons.check_rounded, color: c.colors.primary)
                    : null,
                onTap: () => Navigator.pop(c, s),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (picked == null || picked == _applicant.status) return;
    await ref
        .read(applicantsRepositoryProvider)
        .updateStatus(_applicant.id, picked);
    ref.invalidate(allApplicantsProvider);
    ref.invalidate(jobApplicantsProvider(_applicant.jobId));
    if (!mounted) return;
    setState(() {
      _applicant = _applicant.copyWith(
        status: picked,
        history: [
          ..._applicant.history,
          StatusEvent(status: picked, changedAt: DateTime.now()),
        ],
      );
    });
    showInfoSnack(context, context.l10n.statusUpdatedToast);
  }

  /// Opens a chat with the candidate, reusing the existing chat stack. The
  /// conversation is keyed off the application id; real provisioning between
  /// employer and candidate is a later Supabase-activation item.
  void _message() {
    final a = _applicant;
    context.push(
      Routes.chatDetail('applicant-${a.id}'),
      extra: Conversation(
        id: 'applicant-${a.id}',
        title: a.name,
        avatarUrl: a.avatarUrl,
        subtitle: a.jobTitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final a = _applicant;
    final statusColor = applicationStatusColor(context, a.status);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: a.name),
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
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: colors.surfaceVariant,
                          child: Text(
                            a.name.isEmpty
                                ? '?'
                                : a.name.substring(0, 1).toUpperCase(),
                            style: context.text.headlineSmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          a.name,
                          style: context.text.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (a.headline != null)
                          Text(
                            a.headline!,
                            style: context.text.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            applicationStatusLabel(context, a.status),
                            style: context.text.labelLarge?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _AppliedFor(jobTitle: a.jobTitle),
                  if (a.skills.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l.applicantSkillsLabel,
                      style: context.text.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [for (final s in a.skills) _Chip(s)],
                    ),
                  ],
                  if (a.coverLetter != null && a.coverLetter!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text(l.applicantCoverLabel, style: context.text.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      a.coverLetter!,
                      style: context.text.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                  if (a.screeningQA.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text(l.screeningSection, style: context.text.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    for (final qa in a.screeningQA)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              qa.question,
                              style: context.text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              qa.answer == 'yes'
                                  ? l.yes
                                  : qa.answer == 'no'
                                  ? l.no
                                  : qa.answer,
                              style: context.text.bodyMedium?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Text(l.statusTimelineTitle, style: context.text.titleSmall),
                  const SizedBox(height: AppSpacing.md),
                  for (final e in a.history.reversed)
                    _TimelineRow(
                      label: applicationStatusLabel(context, e.status),
                      date: e.changedAt,
                      color: applicationStatusColor(context, e.status),
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
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _message,
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          side: BorderSide(color: context.colors.border),
                        ),
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                        ),
                        label: Text(l.messageCandidate),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: JzPrimaryButton(
                        label: l.updateStatusCta,
                        onPressed: _pickStatus,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppliedFor extends StatelessWidget {
  const _AppliedFor({required this.jobTitle});
  final String jobTitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.work_outline_rounded, color: colors.primary, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.appliedForLabel,
                  style: context.text.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  jobTitle,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.date,
    required this.color,
  });
  final String label;
  final DateTime date;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: context.text.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
            style: context.text.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(color: colors.textPrimary),
      ),
    );
  }
}
