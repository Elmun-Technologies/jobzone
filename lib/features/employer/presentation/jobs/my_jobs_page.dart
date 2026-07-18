import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/config/env.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../../jobs/domain/job.dart';
import '../../../jobs/presentation/util/job_labels.dart';
import '../../data/employer_jobs_repository.dart';
import 'listing_payment_page.dart';

/// The employer's posted jobs, filterable by lifecycle status, with create /
/// edit / close / reopen actions.
class MyJobsPage extends ConsumerStatefulWidget {
  const MyJobsPage({super.key});

  @override
  ConsumerState<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends ConsumerState<MyJobsPage> {
  /// null = all; otherwise 'open' / 'draft' / 'closed'.
  String? _status;

  Future<void> _setStatus(Job job, String status) async {
    try {
      await ref.read(employerJobsRepositoryProvider).setStatus(job.id, status);
      ref.invalidate(myJobsProvider);
    } catch (e) {
      if (mounted) showErrorSnack(context, localizedError(context, e));
    }
  }

  /// Publishing a draft runs the SAME charge gate as a fresh post — so "save
  /// draft, then publish from the list" can't bypass the first-free/then-paid
  /// rule. First-time (or offline) publishes directly; otherwise the draft goes
  /// through the tier picker + Payme/Click, which publishes it on payment.
  Future<void> _publishDraft(Job job) async {
    final repo = ref.read(employerJobsRepositoryProvider);
    try {
      final charged = Env.hasSupabase && await repo.hasPublishedBefore();
      if (!mounted) return;
      if (charged) {
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) =>
                ListingPaymentPage(jobId: job.id, jobTitle: job.title),
          ),
        );
      } else {
        await repo.setStatus(job.id, 'open');
      }
      ref.invalidate(myJobsProvider);
    } catch (e) {
      if (mounted) showErrorSnack(context, localizedError(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final async = ref.watch(myJobsProvider(_status));
    final filters = <String?, String>{
      null: l.myJobsAll,
      'open': l.jobOpen,
      'draft': l.jobDraft,
      'closed': l.jobClosed,
    };

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.employerPostJob),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(l.postJobCta),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Text(l.navMyJobs, style: context.text.titleLarge),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  for (final e in filters.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: _FilterChip(
                        label: e.value,
                        selected: _status == e.key,
                        onTap: () => setState(() => _status = e.key),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: async.when(
                loading: () => const JobListSkeleton(),
                error: (_, _) => JzErrorState(
                  title: l.errorTitle,
                  message: l.errUnknown,
                  retryLabel: l.retry,
                  onRetry: () => ref.invalidate(myJobsProvider(_status)),
                ),
                data: (jobs) {
                  if (jobs.isEmpty) {
                    return JzEmptyState(
                      icon: Icons.work_outline_rounded,
                      title: l.noJobsTitle,
                      message: l.noJobsBody,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.refresh(myJobsProvider(_status).future),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        96,
                      ),
                      itemCount: jobs.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, i) => _MyJobCard(
                        job: jobs[i],
                        onTap: () => context.push(
                          Routes.employerJobApplicants(jobs[i].id),
                          extra: jobs[i],
                        ),
                        onEdit: () => context.push(
                          Routes.employerEditJob(jobs[i].id),
                          extra: jobs[i],
                        ),
                        onClose: () => _setStatus(jobs[i], 'closed'),
                        onReopen: () => _setStatus(jobs[i], 'open'),
                        onPublish: () => _publishDraft(jobs[i]),
                        onDuplicate: () => context.push(
                          Routes.employerDuplicateJob(jobs[i].id),
                          extra: jobs[i],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Text(
          label,
          style: context.text.labelMedium?.copyWith(
            color: selected ? Colors.white : colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MyJobCard extends StatelessWidget {
  const _MyJobCard({
    required this.job,
    required this.onTap,
    required this.onEdit,
    required this.onClose,
    required this.onReopen,
    required this.onPublish,
    required this.onDuplicate,
  });

  final Job job;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onClose;
  final VoidCallback onReopen;
  final VoidCallback onPublish;
  final VoidCallback onDuplicate;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final tags = [
      ?jobTypeLabel(context, job.jobType),
      ?workingModelLabel(context, job.workingModel),
      ?experienceLabel(context, job.experienceLevel),
    ];
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (job.isBoosted) ...[
                  const JzTopBadge(),
                  const SizedBox(width: AppSpacing.xs),
                ],
                _StatusChip(status: job.status),
                PopupMenuButton<String>(
                  onSelected: (v) => switch (v) {
                    'edit' => onEdit(),
                    'duplicate' => onDuplicate(),
                    'close' => onClose(),
                    'reopen' => onReopen(),
                    'publish' => onPublish(),
                    _ => null,
                  },
                  itemBuilder: (_) => [
                    // A draft's primary action is publishing it (through the
                    // first-free / then-pay-per-listing gate).
                    //
                    // Promote menu item is hidden on mobile until the
                    // wallet-backed boost purchase mirrors the web
                    // PromotePicker flow — today the mobile checkout only
                    // renders a permanently-disabled "coming soon" Pay
                    // button, which is a dead-end for real employers. Web
                    // employers can still promote from /employer/jobs/[id]
                    // /promote (fully wired to the wallet).
                    if (job.status == 'draft')
                      PopupMenuItem(
                        value: 'publish',
                        child: Text(l.publishJob),
                      ),
                    PopupMenuItem(value: 'edit', child: Text(l.jobEditAction)),
                    PopupMenuItem(
                      value: 'duplicate',
                      child: Text(l.jobDuplicateAction),
                    ),
                    if (job.status == 'closed')
                      PopupMenuItem(
                        value: 'reopen',
                        child: Text(l.jobReopenAction),
                      )
                    else if (job.status != 'draft')
                      PopupMenuItem(
                        value: 'close',
                        child: Text(l.jobCloseAction),
                      ),
                  ],
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            if (tags.isNotEmpty)
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [for (final t in tags) _Tag(t)],
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(color: colors.border, height: 1),
            ),
            Row(
              children: [
                Icon(
                  Icons.people_alt_outlined,
                  size: 16,
                  color: colors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${job.applicantsCount} ${l.applicants}',
                  style: context.text.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (job.salaryText != null)
                  Text(
                    job.salaryText!,
                    style: context.text.titleSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final (label, color) = switch (status) {
      'draft' => (l.jobDraft, colors.textSecondary),
      'closed' => (l.jobClosed, const Color(0xFFDB2777)),
      _ => (l.jobOpen, const Color(0xFF16A34A)),
    };
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
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
