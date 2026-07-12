/**
 * Uzbekistan's 14 administrative regions (viloyatlar), canonical names —
 * mirrors `lib/core/utils/uzbekistan_regions.dart` on the mobile side (the
 * source of truth for `jobs.region` values written by the employer post-job
 * form on both clients). Kept as a flat list here; the web admin only needs
 * the region names, not the district breakdown.
 */
export const UZ_REGIONS: string[] = [
  "Toshkent shahri",
  "Toshkent viloyati",
  "Andijon",
  "Farg'ona",
  "Namangan",
  "Samarqand",
  "Buxoro",
  "Navoiy",
  "Qashqadaryo",
  "Surxondaryo",
  "Jizzax",
  "Sirdaryo",
  "Xorazm",
  "Qoraqalpog'iston",
];
