import '../../../localization/generated/app_localizations.dart';
import '../data/categories_repository.dart';

/// Canonical English category name -> stable slug, built from the seed taxonomy.
/// Lets us localize a job's `categoryName` (the `job_categories` display name,
/// which is what the feed carries — the slug isn't on the job row).
final Map<String, String> _slugForName = {
  for (final c in CategoriesRepository.seed) c.name: c.slug,
};

/// Localized display label for a job category, resolved by slug (preferred) or
/// by its canonical English name. Falls back to the given name/slug so an
/// unknown or legacy category still renders something.
String localizedCategory(AppLocalizations l, {String? slug, String? name}) {
  final key = slug ?? (name != null ? _slugForName[name] : null);
  switch (key) {
    case 'engineering':
      return l.categoryEngineering;
    case 'design':
      return l.categoryDesign;
    case 'product':
      return l.categoryProduct;
    case 'marketing':
      return l.categoryMarketing;
    case 'sales':
      return l.categorySales;
    case 'finance':
      return l.categoryFinance;
    case 'hr':
      return l.categoryHr;
    case 'support':
      return l.categorySupport;
    case 'data-ai':
      return l.categoryDataAi;
    case 'operations':
      return l.categoryOperations;
    case 'horeca':
      return l.categoryHoreca;
    case 'retail':
      return l.categoryRetail;
    case 'logistics-delivery':
      return l.categoryLogisticsDelivery;
    case 'construction':
      return l.categoryConstruction;
    case 'driver':
      return l.categoryDriver;
    case 'warehouse':
      return l.categoryWarehouse;
    case 'security':
      return l.categorySecurity;
    case 'cleaning':
      return l.categoryCleaning;
    case 'beauty':
      return l.categoryBeauty;
    case 'manufacturing':
      return l.categoryManufacturing;
    case 'agriculture':
      return l.categoryAgriculture;
    case 'foreign-jobs':
      return l.categoryForeignJobs;
    default:
      return name ?? slug ?? '';
  }
}
