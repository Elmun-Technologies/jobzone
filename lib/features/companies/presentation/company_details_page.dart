import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  l.recentlyAddedJobs,
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final j in jobs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: JobCard(job: j),
                  ),
              ],
            ),
    );
  }
}

class _AboutTab extends ConsumerWidget {
  const _AboutTab({required this.company});
  final Company company;

  TextStyle? _h(BuildContext c) =>
      c.text.titleMedium?.copyWith(fontWeight: FontWeight.w700);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final colors = context.colors;
    final people =
        ref.watch(companyPeopleProvider(company.id)).value ?? const [];
    CompanyPerson? contact;
    for (final p in people) {
      if (p.isRecruiter) {
        contact = p;
        break;
      }
    }
    contact ??= people.isEmpty ? null : people.first;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (company.hasIntroVideo) ...[
          _IntroVideoCard(company: company),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (company.about != null && company.about!.isNotEmpty) ...[
          Text(l.aboutCompany, style: _h(context)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            company.about!,
            style: context.text.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (contact != null) ...[
          Text(l.companyContact, style: _h(context)),
          const SizedBox(height: AppSpacing.md),
          _ContactRow(person: contact),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(l.workingHours, style: _h(context)),
        const SizedBox(height: AppSpacing.sm),
        const _WorkingHours(),
        const SizedBox(height: AppSpacing.lg),
        if (company.headquarters != null &&
            company.headquarters!.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.companyAddress, style: _h(context)),
              Text(
                l.viewOnMap,
                style: context.text.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 18, color: colors.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  company.headquarters!,
                  style: context.text.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _MapPlaceholder(),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(l.companySummary, style: _h(context)),
        const SizedBox(height: AppSpacing.sm),
        _SummaryRow(label: l.websiteLabel, value: company.website),
        _SummaryRow(label: l.headquartersLabel, value: company.headquarters),
        _SummaryRow(
          label: l.foundedLabel,
          value: company.foundedYear?.toString(),
        ),
        _SummaryRow(label: l.companySizeLabel, value: company.size),
        _SummaryRow(label: l.industryLabel, value: company.industry),
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

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.person});
  final CompanyPerson person;

  void _soon(BuildContext context) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(context.l10n.comingSoon)));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: colors.surfaceVariant,
          backgroundImage:
              (person.avatarUrl != null && person.avatarUrl!.isNotEmpty)
              ? CachedNetworkImageProvider(person.avatarUrl!)
              : null,
          child: (person.avatarUrl == null || person.avatarUrl!.isEmpty)
              ? Icon(Icons.person_rounded, color: colors.textSecondary)
              : null,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                person.name,
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
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
        _RoundAction(
          icon: Icons.chat_bubble_rounded,
          onTap: () => _soon(context),
        ),
        const SizedBox(width: AppSpacing.sm),
        _RoundAction(icon: Icons.call_rounded, onTap: () => _soon(context)),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: colors.onPrimary, size: 20),
        ),
      ),
    );
  }
}

class _WorkingHours extends StatelessWidget {
  const _WorkingHours();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toString();
    // Jan 1 2024 is a Monday — render Mon→Sun localized.
    final days = [
      for (var i = 0; i < 7; i++)
        DateFormat.EEEE(
          locale,
        ).format(DateTime(2024, 1, 1).add(Duration(days: i))),
    ];
    return Column(
      children: [
        for (final d in days)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  d,
                  style: context.text.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                Text('09:00 - 18:00', style: context.text.bodyMedium),
              ],
            ),
          ),
      ],
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(Icons.location_on_rounded, color: colors.primary, size: 40),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, this.value});
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
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
              value!,
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
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  '${l.tabPeople} (${people.length})',
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final p in people)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _PersonTile(person: p),
                  ),
              ],
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${l.tabGallery} (${items.length})',
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l.seeAll,
                        style: context.text.labelLarge?.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GalleryGrid(
                    items: items,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                  ),
                ),
              ],
            ),
    );
  }
}
