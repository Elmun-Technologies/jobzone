import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/enums/enums.dart';
import '../../../auth/application/role_controller.dart';
import '../../data/applicants_repository.dart';
import '../../data/company_admin_repository.dart';
import '../../data/employer_stats_provider.dart';
import '../../domain/employer_stats.dart';
import '../applicants/widgets/applicant_card.dart';

/// Employer home: a greeting, hiring stat cards and recent applicants.
class EmployerDashboardPage extends ConsumerWidget {
  const EmployerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final company = ref.watch(myCompanyProvider).value;
    final stats = ref.watch(employerStatsProvider);
    final recent = ref.watch(allApplicantsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(employerStatsProvider);
            ref.invalidate(allApplicantsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.dashboardGreeting,
                          style: context.text.bodyMedium?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                        Text(
                          company?.name ?? l.navDashboard,
                          style: context.text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await applyRole(ref, UserRole.jobSeeker);
                      if (context.mounted) context.go(Routes.home);
                    },
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: Text(l.switchToSeeker),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              stats.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: JzLoader(),
                ),
                error: (_, _) => Text(l.errUnknown),
                data: (s) => _StatGrid(stats: s),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l.recentApplicants,
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(Routes.employerApplicants),
                    child: Text(l.seeAll),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              recent.when(
                loading: () => const JzLoader(),
                error: (_, _) => Text(l.errUnknown),
                data: (applicants) {
                  if (applicants.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xl,
                      ),
                      child: Text(
                        l.noApplicantsTitle,
                        textAlign: TextAlign.center,
                        style: context.text.bodyMedium?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final a in applicants.take(5))
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: ApplicantCard(
                            applicant: a,
                            showJob: true,
                            onTap: () => context.push(
                              Routes.employerApplicant(a.id),
                              extra: a,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});
  final EmployerStats stats;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cards = [
      (l.statOpenJobs, stats.openJobs, Icons.work_outline_rounded),
      (l.applicants, stats.totalApplicants, Icons.people_outline_rounded),
      (l.statNew, stats.newApplicants, Icons.fiber_new_outlined),
      (l.statInterviews, stats.interviews, Icons.event_outlined),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 2.4,
      children: [
        for (final (label, value, icon) in cards)
          _StatCard(label: label, value: value, icon: icon),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.chipBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: colors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  style: context.text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: context.text.bodySmall?.copyWith(
                    color: colors.textSecondary,
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
