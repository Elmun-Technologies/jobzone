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
