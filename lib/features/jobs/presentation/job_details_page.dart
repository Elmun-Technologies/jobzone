import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../reviews/presentation/widgets/company_reviews_view.dart';
import '../application/bookmarks_controller.dart';
import '../application/jobs_providers.dart';
import '../domain/job.dart';
import 'util/job_labels.dart';

class JobDetailsPage extends ConsumerWidget {
  const JobDetailsPage({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final jobAsync = ref.watch(jobByIdProvider(jobId));
    return Scaffold(
      body: jobAsync.when(
        loading: () => const JzLoader(),
        error: (_, _) => JzErrorState(
          title: l.errorTitle,
          message: l.errUnknown,
          retryLabel: l.retry,
          onRetry: () => ref.invalidate(jobByIdProvider(jobId)),
        ),
        data: (job) => job == null
            ? JzEmptyState(icon: Icons.search_off_rounded, title: l.noJobsTitle)
            : _JobDetail(job: job),
      ),
    );
  }
}

class _JobDetail extends ConsumerWidget {
  const _JobDetail({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          _Header(job: job),
          _InfoGrid(job: job),
          const SizedBox(height: AppSpacing.sm),
          TabBar(
            tabs: [
              Tab(text: l.tabAbout),
              Tab(text: l.tabCompany),
              Tab(text: l.tabReviews),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _AboutTab(job: job),
                _CompanyTab(job: job),
                CompanyReviewsView(
                  companyId: job.companyId,
                  companyName: job.companyName,
                ),
              ],
            ),
          ),
          _ApplyBar(jobId: job.id),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l = context.l10n;
    final bookmarked =
        ref.watch(bookmarksControllerProvider).value?.contains(job.id) ?? false;
    final topPad = MediaQuery.of(context).padding.top;
    final letter = job.companyName.isEmpty
        ? '?'
        : job.companyName.substring(0, 1).toUpperCase();

    return Container(
      width: double.infinity,
      color: colors.surfaceVariant,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topPad + AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          Row(
            children: [
              JzCircleButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const Spacer(),
              JzCircleButton(
                icon: bookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                onTap: () => ref
                    .read(bookmarksControllerProvider.notifier)
                    .toggle(job.id),
              ),
              const SizedBox(width: AppSpacing.sm),
              JzCircleButton(
                icon: Icons.share_outlined,
                onTap: () => ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(l.comingSoon))),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: colors.surface, width: 3),
            ),
            alignment: Alignment.center,
            child: Text(
              letter,
              style: context.text.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            job.title,
            textAlign: TextAlign.center,
            style: context.text.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            job.companyName,
            style: context.text.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          if (job.locationText.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: colors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  job.locationText,
                  style: context.text.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final salary = job.salaryText == null
        ? '—'
        : '${job.salaryText}${salaryPeriodLabel(context, job.salaryPeriod) != null ? ' ${salaryPeriodLabel(context, job.salaryPeriod)}' : ''}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  icon: Icons.payments_outlined,
                  label: l.salaryLabel,
                  value: salary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _InfoCard(
                  icon: Icons.work_outline_rounded,
                  label: l.fieldJobType,
                  value: jobTypeLabel(context, job.jobType) ?? '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  icon: Icons.laptop_mac_rounded,
                  label: l.fieldWorkingModel,
                  value: workingModelLabel(context, job.workingModel) ?? '—',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _InfoCard(
                  icon: Icons.bar_chart_rounded,
                  label: l.fieldLevel,
                  value: experienceLabel(context, job.experienceLevel) ?? '—',
                ),
              ),
            ],
          ),
          if (job.payoutFrequency != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    icon: Icons.event_repeat_outlined,
                    label: l.payoutFreqLabel,
                    value:
                        payoutFrequencyLabel(context, job.payoutFrequency) ??
                        '—',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

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
          Icon(icon, color: colors.primary, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.text.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: context.text.titleSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (job.womenFriendly || job.disabilityFriendly)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (job.womenFriendly)
                  _MarkerChip(
                    icon: Icons.diversity_1_rounded,
                    label: l.fieldWomenFriendly,
                  ),
                if (job.disabilityFriendly)
                  _MarkerChip(
                    icon: Icons.accessible_rounded,
                    label: l.fieldDisabilityFriendly,
                  ),
              ],
            ),
          ),
        if (job.showPhoneOnListing && (job.contactPhone?.isNotEmpty ?? false))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: _ContactTile(phone: job.contactPhone!),
          ),
        if (job.description != null && job.description!.isNotEmpty)
          _Section(
            title: l.aboutThisJob,
            child: MarkdownBody(
              data: job.description!,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                  .copyWith(
                    p: context.text.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      height: 1.5,
                    ),
                  ),
            ),
          ),
        if (job.responsibilities != null && job.responsibilities!.isNotEmpty)
          _Section(
            title: l.jobDescription,
            child: _Bullets(text: job.responsibilities!),
          ),
        if (job.requirements != null && job.requirements!.isNotEmpty)
          _Section(
            title: l.minimumQualification,
            child: _Bullets(text: job.requirements!),
          ),
        if (job.benefits != null && job.benefits!.isNotEmpty)
          _Section(
            title: l.perksAndBenefits,
            child: _Checks(text: job.benefits!),
          ),
        if (job.skills.isNotEmpty) _QualificationsCheck(skills: job.skills),
        if (job.driverLicenses.isNotEmpty)
          _Section(
            title: l.driverLicenseLabel,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [for (final c in job.driverLicenses) _SkillChip(c)],
            ),
          ),
        if (job.languages.isNotEmpty)
          _Section(
            title: l.languagesLabel,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final lang in job.languages)
                  _SkillChip(jobLanguageLabel(context, lang)),
              ],
            ),
          ),
        _Section(
          title: l.jobSummary,
          child: Column(
            children: [
              if (job.categoryName != null)
                _SummaryRow(label: l.jobCategory, value: job.categoryName!),
              if (job.salaryText != null)
                _SummaryRow(
                  label: l.payBasisLabel,
                  value: job.salaryGross ? l.salaryGross : l.salaryNet,
                ),
              if (job.addressText != null && job.addressText!.isNotEmpty)
                _SummaryRow(label: l.fieldWorkAddress, value: job.addressText!),
              if (schedulePatternLabel(context, job.schedulePattern) != null)
                _SummaryRow(
                  label: l.fieldSchedulePattern,
                  value: schedulePatternLabel(context, job.schedulePattern)!,
                ),
              if (formalizationLabel(context, job.formalization) != null)
                _SummaryRow(
                  label: l.fieldFormalization,
                  value: formalizationLabel(context, job.formalization)!,
                ),
              if (job.hoursPerDay != null)
                _SummaryRow(
                  label: l.fieldHoursPerDay,
                  value: '${job.hoursPerDay}',
                ),
              if (job.nightShift)
                _SummaryRow(label: l.fieldNightShift, value: l.yes),
              if (job.postedAt != null)
                _SummaryRow(
                  label: l.jobPostedOn,
                  value: DateFormat.yMMMMd().format(job.postedAt!),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets({required this.text});
  final String text;

  List<String> get _items {
    final parts = text.contains('\n')
        ? text.split('\n')
        : text.split(RegExp(r'(?<=\.)\s+'));
    return parts.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7, right: AppSpacing.sm),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: context.text.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Checks extends StatelessWidget {
  const _Checks({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items =
        (text.contains('\n')
                ? text.split('\n')
                : text.split(RegExp(r'(?<=\.)\s+')))
            .map((e) => e.trim().replaceAll(RegExp(r'\.$'), ''))
            .where((e) => e.isNotEmpty)
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: colors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(item, style: context.text.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Interactive "do you have these skills?" self-check (Glassdoor-style). Shows
/// the job's required skills as toggle rows so a seeker can gauge their fit
/// before applying; the count + bar update live. Purely local — nothing is
/// stored or sent.
class _QualificationsCheck extends StatefulWidget {
  const _QualificationsCheck({required this.skills});
  final List<String> skills;

  @override
  State<_QualificationsCheck> createState() => _QualificationsCheckState();
}

class _QualificationsCheckState extends State<_QualificationsCheck> {
  final _have = <String>{};

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final total = widget.skills.length;
    final have = _have.length;
    return _Section(
      title: l.qualificationsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.qualificationsHint,
            style: context.text.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final s in widget.skills)
            InkWell(
              onTap: () => setState(
                () => _have.contains(s) ? _have.remove(s) : _have.add(s),
              ),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      _have.contains(s)
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: _have.contains(s)
                          ? colors.success
                          : colors.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(s, style: context.text.bodyMedium)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : have / total,
              minHeight: 6,
              backgroundColor: colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(colors.success),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$have / $total ${l.qualificationsMatch}',
            style: context.text.labelMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(label, style: context.text.labelMedium),
    );
  }
}

/// Inclusive marker pill (women-friendly / disability-friendly).
class _MarkerChip extends StatelessWidget {
  const _MarkerChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: context.text.labelMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Employer contact phone shown on the listing (when the employer opted in).
class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.phone});
  final String phone;

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
          Icon(Icons.phone_rounded, color: colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.fieldContactPhone,
                  style: context.text.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                SelectableText(
                  phone,
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.text.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: context.text.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyTab extends StatelessWidget {
  const _CompanyTab({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Text(
              job.companyName,
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (job.companyVerified) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.verified_rounded, size: 18, color: colors.primary),
            ],
          ],
        ),
        if (job.locationText.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            job.locationText,
            style: context.text.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: () => context.push(Routes.companyDetails(job.companyId)),
          icon: const Icon(Icons.business_rounded),
          label: Text(l.viewCompany),
        ),
      ],
    );
  }
}

class _ApplyBar extends StatelessWidget {
  const _ApplyBar({required this.jobId});
  final String jobId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: JzPrimaryButton(
          label: context.l10n.applyForJob,
          onPressed: () => context.push(Routes.applyJob(jobId)),
        ),
      ),
    );
  }
}
