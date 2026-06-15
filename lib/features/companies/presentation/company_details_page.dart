import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../jobs/application/jobs_providers.dart';
import '../../jobs/presentation/widgets/job_card.dart';
import '../../reviews/presentation/widgets/company_reviews_view.dart';
import '../data/companies_repository.dart';
import '../domain/company.dart';
import 'widgets/company_header.dart';
import 'widgets/gallery_grid.dart';

class CompanyDetailsPage extends ConsumerWidget {
  const CompanyDetailsPage({super.key, required this.companyId});
  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(companyByIdProvider(companyId));
    return Scaffold(
      appBar: AppBar(),
      body: async.when(
        loading: () => const JzLoader(),
        error: (_, _) => Center(child: Text(l.errUnknown)),
        data: (company) => company == null
            ? JzEmptyState(
                icon: Icons.business_rounded,
                title: l.companyNotFound,
              )
            : _CompanyDetail(company: company),
      ),
    );
  }
}

class _CompanyDetail extends StatelessWidget {
  const _CompanyDetail({required this.company});
  final Company company;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          CompanyHeader(company: company),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l.tabOpenJobs),
              Tab(text: l.tabAbout),
              Tab(text: l.tabReviews),
              Tab(text: l.tabPeople),
              Tab(text: l.tabGallery),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _OpenJobsTab(companyId: company.id),
                _AboutTab(company: company),
                CompanyReviewsView(
                  companyId: company.id,
                  companyName: company.name,
                ),
                _PeopleTab(companyId: company.id),
                _GalleryTab(company: company),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenJobsTab extends ConsumerWidget {
  const _OpenJobsTab({required this.companyId});
  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(companyJobsProvider(companyId));
    return async.when(
      loading: () => const JobListSkeleton(),
      error: (_, _) => Center(child: Text(l.errUnknown)),
      data: (jobs) => jobs.isEmpty
          ? JzEmptyState(icon: Icons.work_outline_rounded, title: l.noJobsTitle)
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: jobs.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) => JobCard(job: jobs[i]),
            ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.company});
  final Company company;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (company.hasIntroVideo) ...[
          _IntroVideoCard(company: company),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (company.about != null && company.about!.isNotEmpty) ...[
          Text(l.aboutCompany, style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            company.about!,
            style: context.text.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        _InfoRow(
          icon: Icons.factory_outlined,
          label: l.industryLabel,
          value: company.industry,
        ),
        _InfoRow(
          icon: Icons.groups_outlined,
          label: l.companySizeLabel,
          value: company.size,
        ),
        _InfoRow(
          icon: Icons.event_outlined,
          label: l.foundedLabel,
          value: company.foundedYear?.toString(),
        ),
        _InfoRow(
          icon: Icons.location_on_outlined,
          label: l.headquartersLabel,
          value: company.headquarters,
        ),
        _InfoRow(
          icon: Icons.language_rounded,
          label: l.websiteLabel,
          value: company.website,
        ),
      ],
    );
  }
}

class _IntroVideoCard extends StatelessWidget {
  const _IntroVideoCard({required this.company});
  final Company company;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => context.push(Routes.companyIntroVideo(company.id)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.play_arrow_rounded, color: colors.onPrimary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                context.l10n.watchIntroVideo,
                style: context.text.titleSmall,
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, this.value});
  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.text.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                Text(value!, style: context.text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeopleTab extends ConsumerWidget {
  const _PeopleTab({required this.companyId});
  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(companyPeopleProvider(companyId));
    return async.when(
      loading: () => const JzLoader(),
      error: (_, _) => Center(child: Text(l.errUnknown)),
      data: (people) => people.isEmpty
          ? JzEmptyState(
              icon: Icons.people_outline_rounded,
              title: l.noPeopleTitle,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: people.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) => _PersonTile(person: people[i]),
            ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.person});
  final CompanyPerson person;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: colors.chipBackground,
          backgroundImage:
              (person.avatarUrl != null && person.avatarUrl!.isNotEmpty)
              ? CachedNetworkImageProvider(person.avatarUrl!)
              : null,
          child: (person.avatarUrl == null || person.avatarUrl!.isEmpty)
              ? Icon(Icons.person_rounded, color: colors.primary)
              : null,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(person.name, style: context.text.titleSmall),
              if (person.title != null)
                Text(
                  person.title!,
                  style: context.text.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        if (person.isRecruiter)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              l.recruiterBadge,
              style: context.text.labelSmall?.copyWith(color: colors.primary),
            ),
          ),
      ],
    );
  }
}

class _GalleryTab extends ConsumerWidget {
  const _GalleryTab({required this.company});
  final Company company;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(companyGalleryProvider(company.id));
    return async.when(
      loading: () => const JzLoader(),
      error: (_, _) => Center(child: Text(l.errUnknown)),
      data: (items) => items.isEmpty
          ? JzEmptyState(
              icon: Icons.photo_library_outlined,
              title: l.noGalleryTitle,
            )
          : GalleryGrid(
              items: items,
              padding: const EdgeInsets.all(AppSpacing.lg),
            ),
    );
  }
}
