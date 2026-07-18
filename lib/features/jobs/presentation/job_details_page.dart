import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/routes.dart';
import '../../../core/config/env.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/widgets/snackbars.dart';
import '../../applications/application/applications_controller.dart';
import '../../employer/data/ai_content_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../reviews/presentation/widgets/company_reviews_view.dart';
import '../application/bookmarks_controller.dart';
import '../application/jobs_providers.dart';
import '../domain/job.dart';
import 'category_label.dart';
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
        loading: () => const DetailPageSkeleton(),
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
          // The apply bar rises from the bottom after the content settles —
          // draws the eye to the primary action without blocking reading.
          JzFadeSlideIn(
            delay: const Duration(milliseconds: 200),
            dy: 24,
            child: _ApplyBar(job: job),
          ),
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
                // Copy the job's public web URL to the clipboard. `share_plus`
                // would open the OS share sheet but adds ~200KB to the AAB for
                // one feature; the copy-and-toast pattern is the standard
                // Uzbek app UX (Telegram / OLX / hh.uz all do this) and works
                // identically on iOS + Android + web.
                onTap: () async {
                  final url = '${Env.webBaseUrl}/uz/jobs/${job.id}';
                  await Clipboard.setData(ClipboardData(text: url));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(l.linkCopied)));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Builder(
            builder: (context) {
              final fallback = Center(
                child: Text(
                  letter,
                  style: context.text.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
              final url = job.companyLogoUrl;
              return Container(
                height: 72,
                width: 72,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 3),
                ),
                child: (url == null || url.isEmpty)
                    ? fallback
                    : CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => fallback,
                      ),
              );
            },
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
          // The info rows cascade in — a quick, scannable reveal of the
          // decision-making facts (salary, type, model, level).
          JzFadeSlideIn(
            dy: 12,
            child: Row(
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
          ),
          const SizedBox(height: AppSpacing.md),
          JzFadeSlideIn(
            delay: const Duration(milliseconds: 90),
            dy: 12,
            child: Row(
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
        if (job.skills.isNotEmpty) ...[
          _MatchCard(job: job),
          const SizedBox(height: AppSpacing.lg),
        ],
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
                _SummaryRow(
                  label: l.jobCategory,
                  value: localizedCategory(l, name: job.categoryName),
                ),
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

/// "Am I a good match?" — runs the AI / skill-overlap match
/// (ai_content_repository) against the signed-in seeker's profile skills and
/// shows the fit score, strengths and gaps. Adapts Glassdoor's resume-match.
class _MatchCard extends ConsumerStatefulWidget {
  const _MatchCard({required this.job});
  final Job job;

  @override
  ConsumerState<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends ConsumerState<_MatchCard> {
  bool _loading = false;
  JobMatch? _result;

  Future<void> _run() async {
    setState(() => _loading = true);
    final profile = ref.read(currentProfileProvider).value;
    final locale = Localizations.localeOf(context).languageCode;
    try {
      final m = await ref
          .read(aiContentRepositoryProvider)
          .matchJob(
            title: widget.job.title,
            jobSkills: widget.job.skills,
            description: widget.job.description,
            mySkills: profile?.skills ?? const [],
            myHeadline: profile?.headline,
            locale: locale,
          );
      if (mounted) {
        setState(() {
          _result = m;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showErrorSnack(context, localizedError(context, e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final r = _result;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.chipBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: r == null
          ? Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(l.matchPrompt, style: context.text.bodyMedium),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: _loading ? null : _run,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    shape: const StadiumBorder(),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l.matchCta),
                ),
              ],
            )
          : _MatchResult(result: r),
    );
  }
}

class _MatchResult extends StatelessWidget {
  const _MatchResult({required this.result});
  final JobMatch result;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final pct = result.score.clamp(0, 100);
    final tone = pct >= 70
        ? colors.success
        : (pct >= 40 ? colors.gold : colors.danger);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$pct%',
              style: context.text.headlineMedium?.copyWith(
                color: tone,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                l.qualificationsMatch,
                style: context.text.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 6,
            backgroundColor: colors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(tone),
          ),
        ),
        if (result.summary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(result.summary, style: context.text.bodyMedium),
        ],
        if (result.strengths.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            l.matchStrengths,
            style: context.text.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final s in result.strengths)
                _MatchChip(
                  label: s,
                  color: colors.success,
                  icon: Icons.check_rounded,
                ),
            ],
          ),
        ],
        if (result.gaps.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            l.matchGaps,
            style: context.text.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final s in result.gaps)
                _MatchChip(
                  label: s,
                  color: colors.textSecondary,
                  icon: Icons.add_rounded,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MatchChip extends StatelessWidget {
  const _MatchChip({
    required this.label,
    required this.color,
    required this.icon,
  });
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: context.text.labelSmall?.copyWith(color: color)),
        ],
      ),
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

/// Sticky footer: the salary (the decision the seeker is making) above a
/// full-width apply CTA. A top border + shadow separate it from the scrolling
/// content.
class _ApplyBar extends ConsumerWidget {
  const _ApplyBar({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final colors = context.colors;
    final applied = ref.watch(hasAppliedProvider(job.id));
    final salary = job.salaryText;
    final period = salaryPeriodLabel(context, job.salaryPeriod);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (salary != null && salary.isNotEmpty) ...[
                Row(
                  children: [
                    Text(
                      l.salaryLabel,
                      style: context.text.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: RichText(
                          maxLines: 1,
                          text: TextSpan(
                            text: salary,
                            style: context.text.titleMedium?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                            children: [
                              if (period != null)
                                TextSpan(
                                  text: ' $period',
                                  style: context.text.bodySmall?.copyWith(
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              JzPrimaryButton(
                label: applied ? l.appliedLabel : l.applyForJob,
                onPressed: applied
                    ? null
                    : () => context.push(Routes.applyJob(job.id)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen read-only preview of a [Job] used by the employer post-job form
/// ("Oldindan ko'rish" / Preview). Wraps [_JobDetail] with a dismiss button.
class JobPreviewPage extends StatelessWidget {
  const JobPreviewPage({super.key, required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _JobDetail(job: job),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            child: Text(context.l10n.closePreview),
          ),
        ),
      ),
    );
  }
}
