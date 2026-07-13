import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../jobs/presentation/widgets/job_card.dart';
import '../data/company_follow_repository.dart';
import '../domain/company.dart';

/// "Подписки" (Obunalar): the companies the seeker follows and a feed of their
/// open vacancies. Following is toggled from each company's page (the header
/// bell). Distinct from saved searches, which lives on its own screen.
class SubscriptionsPage extends ConsumerWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final companiesAsync = ref.watch(followedCompaniesProvider);
    final jobsAsync = ref.watch(followedCompanyJobsProvider);

    void refresh() {
      ref.invalidate(followedCompaniesProvider);
      ref.invalidate(followedCompanyJobsProvider);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.subscriptions),
            ),
            Expanded(
              child: companiesAsync.when(
                loading: () => const JzLoader(),
                error: (_, _) => JzErrorState(
                  title: l.errorTitle,
                  message: l.errUnknown,
                  retryLabel: l.retry,
                  onRetry: refresh,
                ),
                data: (companies) => companies.isEmpty
                    ? Center(
                        child: JzEmptyState(
                          icon: Icons.notifications_none_rounded,
                          title: l.subscriptionsEmptyTitle,
                          message: l.subscriptionsEmptyBody,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => refresh(),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.xl,
                          ),
                          children: [
                            SectionHeader(title: l.subscriptionsCompanies),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              height: 104,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: companies.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: AppSpacing.md),
                                itemBuilder: (_, i) =>
                                    _CompanyChip(company: companies[i]),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            SectionHeader(title: l.subscriptionsJobs),
                            const SizedBox(height: AppSpacing.md),
                            jobsAsync.when(
                              loading: () => const JobListSkeleton(
                                count: 3,
                                padding: EdgeInsets.zero,
                              ),
                              error: (_, _) => _EmptyText(l.errUnknown),
                              data: (jobs) => jobs.isEmpty
                                  ? _EmptyText(l.subscriptionsNoJobs)
                                  : Column(
                                      children: [
                                        for (final j in jobs)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: AppSpacing.md,
                                            ),
                                            child: JobCard(job: j),
                                          ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A followed-company avatar + name; tapping opens the company page (where the
/// user can unfollow via the header bell).
class _CompanyChip extends StatelessWidget {
  const _CompanyChip({required this.company});
  final Company company;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final logo = company.logoUrl;
    return GestureDetector(
      onTap: () => context.push(Routes.companyDetails(company.id)),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: (logo == null || logo.isEmpty)
                  ? Text(
                      company.name.isEmpty
                          ? '?'
                          : company.name.substring(0, 1).toUpperCase(),
                      style: context.text.titleLarge?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: logo,
                      fit: BoxFit.cover,
                      width: 60,
                      height: 60,
                      errorWidget: (_, _, _) => const Icon(
                        Icons.business_rounded,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              company.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: context.text.bodyMedium?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}
