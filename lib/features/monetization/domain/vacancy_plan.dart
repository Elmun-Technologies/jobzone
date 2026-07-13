/// The employer plan tiers — priced by how many *active* (open) vacancies a
/// company runs at once, not per-post. The first vacancy is always free; beyond
/// that it's a flat monthly volume tier. Mirrors the web source of truth in
/// `webapp/src/lib/pricing-tiers.ts`; the numbers are guarded by
/// `test/monetization/vacancy_plan_test.dart`. `maxJobs == null` means unlimited
/// (the "50+" tier). Tier names are kept as English brand words in every locale
/// (Free / Standard / Highlight / Business), so only the caps and descriptions
/// are localized.
enum VacancyPlanTier { free, standard, highlight, business }

class VacancyPlan {
  const VacancyPlan({
    required this.tier,
    required this.maxJobs,
    required this.priceUzs,
    this.featured = false,
  });

  final VacancyPlanTier tier;

  /// Inclusive upper bound of active vacancies; null = unlimited.
  final int? maxJobs;
  final int priceUzs;

  /// The tier we highlight as the everyday sweet spot.
  final bool featured;

  bool get isFree => priceUzs <= 0;

  /// The English brand name shown on the card (same across locales).
  String get name => switch (tier) {
    VacancyPlanTier.free => 'Free',
    VacancyPlanTier.standard => 'Standard',
    VacancyPlanTier.highlight => 'Highlight',
    VacancyPlanTier.business => 'Business',
  };
}

/// The four tiers, cheapest first. Keep in sync with `PLAN_TIERS` on the web.
const kVacancyPlans = <VacancyPlan>[
  VacancyPlan(tier: VacancyPlanTier.free, maxJobs: 1, priceUzs: 0),
  VacancyPlan(tier: VacancyPlanTier.standard, maxJobs: 10, priceUzs: 99000),
  VacancyPlan(
    tier: VacancyPlanTier.highlight,
    maxJobs: 50,
    priceUzs: 199000,
    featured: true,
  ),
  VacancyPlan(tier: VacancyPlanTier.business, maxJobs: null, priceUzs: 499000),
];

/// The cheapest tier whose cap covers [activeJobs] open vacancies.
VacancyPlan vacancyPlanForActiveJobs(int activeJobs) {
  for (final p in kVacancyPlans) {
    if (p.maxJobs != null && activeJobs <= p.maxJobs!) return p;
  }
  return kVacancyPlans.last;
}
