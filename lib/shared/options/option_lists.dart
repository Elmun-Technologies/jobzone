import '../../localization/generated/app_localizations.dart';

/// Shared, localized option lists (wire value → display label) used by the
/// preference steps, the search filter sheet and the manual location picker.
///
/// Wire values are deliberately NOT localized:
/// - job-title keywords are matched with ILIKE against employer-written job
///   titles (the product is Uzbek-first, so the Uzbek keyword matches best);
/// - city values match the `city` column / mock data ("Tashkent" …).

/// Blue-collar job-title keywords for the title facet / preference step
/// (replaces the old hardcoded white-collar English list, which was both
/// untranslated and never matched real postings).
Map<String, String> jobTitleOptions(AppLocalizations l) => {
  'Oshpaz': l.jobTitleChef,
  'Ofitsiant': l.jobTitleWaiter,
  'Haydovchi': l.jobTitleDriver,
  'Kuryer': l.jobTitleCourier,
  'Sotuvchi': l.jobTitleSalesperson,
  'Kassir': l.jobTitleCashier,
  'Qorovul': l.jobTitleGuard,
  'Farrosh': l.jobTitleCleaner,
  'Omborchi': l.jobTitleWarehouse,
  'Qurilish': l.jobTitleBuilder,
  'Administrator': l.jobTitleAdministrator,
  'Elektrik': l.jobTitleElectrician,
};

/// Major cities: wire value → localized label.
Map<String, String> cityOptions(AppLocalizations l) => {
  'Tashkent': l.cityTashkent,
  'Samarkand': l.citySamarkand,
  'Bukhara': l.cityBukhara,
  'Andijan': l.cityAndijan,
  'Namangan': l.cityNamangan,
  'Fergana': l.cityFergana,
  'Nukus': l.cityNukus,
};

/// Localized promotion-product name for a catalog [code]. The live catalog and
/// the offline seed both store Uzbek-only `name`/`description`, so displaying
/// `product.name` directly leaves ru/en employers reading Uzbek — route the
/// stable product code through l10n instead. Falls back to [fallback] (the raw
/// stored name) for any unknown/new code.
String promotionName(AppLocalizations l, String code, {String fallback = ''}) =>
    switch (code) {
      'start' => l.promoStartName,
      'featured' => l.promoFeaturedName,
      'top_3' => l.promoTop3Name,
      'top_7' => l.promoTop7Name,
      'top_30' => l.promoTop30Name,
      'ai_screening' => l.promoAiName,
      _ => fallback,
    };

/// Localized promotion-product description for a catalog [code]; null for an
/// unknown code so callers can fall back to the raw stored description.
String? promotionDesc(AppLocalizations l, String code) => switch (code) {
  'start' => l.promoStartDesc,
  'featured' => l.promoFeaturedDesc,
  'top_3' => l.promoTop3Desc,
  'top_7' => l.promoTop7Desc,
  'top_30' => l.promoTop30Desc,
  'ai_screening' => l.promoAiDesc,
  _ => null,
};
