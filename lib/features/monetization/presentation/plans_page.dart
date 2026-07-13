import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../domain/promotion.dart' show formatUzs;
import '../domain/vacancy_plan.dart';

/// Employer plan tiers, priced by how many active vacancies a company runs at
/// once (first one free). The web mirror is the `/pricing` page and the
/// `/about` pricing section; the tier numbers live in
/// `domain/vacancy_plan.dart`. Informational for now — checkout/capacity
/// enforcement is wired separately.
class PlansPage extends StatelessWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.plansTitle),
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
                  Text(
                    l.plansSubtitle,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (final plan in kVacancyPlans)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _PlanCard(plan: plan),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l.plansNote,
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});
  final VacancyPlan plan;

  String _cap(BuildContext context) {
    final l = context.l10n;
    return switch (plan.tier) {
      VacancyPlanTier.free => l.planFreeCap,
      VacancyPlanTier.standard => l.planStandardCap,
      VacancyPlanTier.highlight => l.planHighlightCap,
      VacancyPlanTier.business => l.planBusinessCap,
    };
  }

  String _desc(BuildContext context) {
    final l = context.l10n;
    return switch (plan.tier) {
      VacancyPlanTier.free => l.planFreeDesc,
      VacancyPlanTier.standard => l.planStandardDesc,
      VacancyPlanTier.highlight => l.planHighlightDesc,
      VacancyPlanTier.business => l.planBusinessDesc,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final featured = plan.featured;
    final accent = colors.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: featured ? colors.chipBackground : colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: featured ? accent : colors.border,
          width: featured ? 1.8 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                plan.name,
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (featured)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l.planPopular,
                    style: context.text.labelSmall?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _cap(context),
            style: context.text.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            plan.isFree ? l.freeLabel : formatUzs(plan.priceUzs),
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: plan.isFree ? colors.textPrimary : accent,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _desc(context),
            style: context.text.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
