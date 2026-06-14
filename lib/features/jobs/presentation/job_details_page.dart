import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
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
      appBar: AppBar(),
      body: jobAsync.when(
        loading: () => const JzLoader(),
        error: (_, _) => Center(child: Text(l.errUnknown)),
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
    final colors = context.colors;
    final bookmarked =
        ref.watch(bookmarksControllerProvider).value?.contains(job.id) ?? false;
    final chips = [
      ?jobTypeLabel(context, job.jobType),
      ?workingModelLabel(context, job.workingModel),
      ?experienceLabel(context, job.experienceLevel),
    ];

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        height: 56,
                        width: 56,
                        color: colors.chipBackground,
                        child:
                            (job.companyLogoUrl == null ||
                                job.companyLogoUrl!.isEmpty)
                            ? Icon(
                                Icons.business_rounded,
                                color: colors.primary,
                              )
                            : CachedNetworkImage(
                                imageUrl: job.companyLogoUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => Icon(
                                  Icons.business_rounded,
                                  color: colors.primary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job.title, style: context.text.titleLarge),
                          Text(
                            [
                              job.companyName,
                              if (job.locationText.isNotEmpty) job.locationText,
                            ].join(' • '),
                            style: context.text.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [for (final c in chips) Chip(label: Text(c))],
                  ),
                ],
              ],
            ),
          ),
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
                _ReviewsTab(),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () => ref
                        .read(bookmarksControllerProvider.notifier)
                        .toggle(job.id),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(56, 52),
                      side: BorderSide(color: colors.border),
                    ),
                    child: Icon(
                      bookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: bookmarked ? colors.primary : colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: JzPrimaryButton(
                      label: l.applyNow,
                      onPressed: () => context.push(Routes.applyJob(job.id)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.text.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          body,
          style: context.text.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (job.salaryText != null)
          _Section(title: l.salaryLabel, body: job.salaryText!),
        if (job.description != null && job.description!.isNotEmpty)
          _Section(title: l.descriptionLabel, body: job.description!),
        if (job.responsibilities != null && job.responsibilities!.isNotEmpty)
          _Section(title: l.responsibilitiesLabel, body: job.responsibilities!),
        if (job.requirements != null && job.requirements!.isNotEmpty)
          _Section(title: l.requirementsLabel, body: job.requirements!),
        if (job.benefits != null && job.benefits!.isNotEmpty)
          _Section(title: l.benefitsLabel, body: job.benefits!),
        if (job.skills.isNotEmpty)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [for (final s in job.skills) Chip(label: Text(s))],
          ),
      ],
    );
  }
}

class _CompanyTab extends StatelessWidget {
  const _CompanyTab({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Text(job.companyName, style: context.text.titleMedium),
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
        Text(
          context.l10n.aboutCompanyComingSoon,
          style: context.text.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return JzEmptyState(
      icon: Icons.reviews_outlined,
      title: l.reviewsEmptyTitle,
      message: l.reviewsEmptyBody,
    );
  }
}
