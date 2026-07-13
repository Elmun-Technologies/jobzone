import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/monetization/domain/vacancy_plan.dart';

void main() {
  group('vacancy plan tiers', () {
    test('four tiers at the agreed caps and prices', () {
      expect(
        kVacancyPlans.map((p) => (p.tier, p.maxJobs, p.priceUzs)).toList(),
        [
          (VacancyPlanTier.free, 1, 0),
          (VacancyPlanTier.standard, 10, 99000),
          (VacancyPlanTier.highlight, 50, 199000),
          (VacancyPlanTier.business, null, 499000),
        ],
      );
    });

    test('exactly one featured tier', () {
      expect(kVacancyPlans.where((p) => p.featured).length, 1);
    });

    test('names are the English brand words in tier order', () {
      expect(kVacancyPlans.map((p) => p.name).toList(), [
        'Free',
        'Standard',
        'Highlight',
        'Business',
      ]);
    });

    test('vacancyPlanForActiveJobs picks the cheapest covering tier', () {
      expect(vacancyPlanForActiveJobs(1).tier, VacancyPlanTier.free);
      expect(vacancyPlanForActiveJobs(2).tier, VacancyPlanTier.standard);
      expect(vacancyPlanForActiveJobs(10).tier, VacancyPlanTier.standard);
      expect(vacancyPlanForActiveJobs(11).tier, VacancyPlanTier.highlight);
      expect(vacancyPlanForActiveJobs(50).tier, VacancyPlanTier.highlight);
      expect(vacancyPlanForActiveJobs(51).tier, VacancyPlanTier.business);
      expect(vacancyPlanForActiveJobs(9999).tier, VacancyPlanTier.business);
    });
  });
}
