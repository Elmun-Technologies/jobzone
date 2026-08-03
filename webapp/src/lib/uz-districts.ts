/**
 * Uzbekistan's regions (viloyatlar) → their districts/cities (tumanlar).
 *
 * A straight port of `lib/core/utils/uzbekistan_regions.dart`, which is the
 * source of truth for the `jobs.region` / `jobs.district` values the mobile
 * employer form writes. The résumé's desired location has to be drawn from the
 * same list, or the two sides never compare equal — the whole point of asking
 * for a region instead of free text.
 *
 * Keep the two files in step: a name that exists here but not there (or the
 * other way round) is a silent matching hole.
 */
export const UZ_DISTRICTS: Record<string, string[]> = {
  "Toshkent shahri": [
    "Bektemir",
    "Chilonzor",
    "Hamza",
    "Mirzo Ulug'bek",
    "Mirobod",
    "Olmazor",
    "Sergeli",
    "Shayxontohur",
    "Uchtepa",
    "Yakkasaroy",
    "Yunusobod",
  ],
  "Toshkent viloyati": [
    "Angren",
    "Bekobod",
    "Bo'stonliq",
    "Bo'ka",
    "Chirchiq",
    "Chinoz",
    "Ohangaron",
    "Parkent",
    "Piskent",
    "Qibray",
    "Toshloq",
    "Urtachirchiq",
    "Yuqorichirchiq",
    "Zangiota",
  ],
  Andijon: [
    "Andijon",
    "Asaka",
    "Baliqchi",
    "Bo'z",
    "Buloqboshi",
    "Izboskan",
    "Jalolquduq",
    "Marhamat",
    "Oltinko'l",
    "Paxtaobod",
    "Shahrixon",
    "Ulug'nor",
    "Xo'jaobod",
  ],
  "Farg'ona": [
    "Beshariq",
    "Bog'dod",
    "Buvayda",
    "Dang'ara",
    "Farg'ona",
    "Furqat",
    "Oltiariq",
    "Quva",
    "Rishton",
    "So'x",
    "Toshloq",
    "Uchko'prik",
    "Yozyovon",
  ],
  Namangan: [
    "Chortoq",
    "Chust",
    "Kosonsoy",
    "Mingbuloq",
    "Namangan",
    "Norin",
    "Pop",
    "To'raqo'rg'on",
    "Uychi",
    "Yangidaryo",
  ],
  Samarqand: [
    "Bulung'ur",
    "Ishtixon",
    "Jomboy",
    "Kattaqo'rg'on",
    "Narpay",
    "Nurobod",
    "Oqdaryo",
    "Pastdarg'om",
    "Payariq",
    "Samarqand",
    "Tayloq",
    "Urgut",
  ],
  Buxoro: [
    "Buxoro",
    "G'ijduvon",
    "Jondor",
    "Kogon",
    "Olot",
    "Peshku",
    "Romitan",
    "Shofirkon",
    "Vobkent",
    "Qorovulbozor",
  ],
  Navoiy: [
    "Konimex",
    "Navbahor",
    "Navoiy",
    "Nurota",
    "Qiziltepa",
    "Tomdi",
    "Uchquduq",
    "Xatirchi",
  ],
  Qashqadaryo: [
    "Chiroqchi",
    "Dehqonobod",
    "G'uzor",
    "Kasbi",
    "Kitob",
    "Koson",
    "Mirishkor",
    "Muborak",
    "Nishon",
    "Qamashi",
    "Qarshi",
    "Shahrisabz",
    "Yakkabog'",
  ],
  Surxondaryo: [
    "Angor",
    "Boysun",
    "Denov",
    "Jarqo'rg'on",
    "Muzrabot",
    "Oltinsoy",
    "Qiziriq",
    "Sariosiyo",
    "Sherobod",
    "Sho'rchi",
    "Termiz",
    "Uzun",
  ],
  Jizzax: [
    "Arnasoy",
    "Baxmal",
    "Do'stlik",
    "Forish",
    "G'allaorol",
    "Jizzax",
    "Pakhtakor",
    "Yangiobod",
    "Zafarobod",
    "Zarbdor",
    "Zomin",
  ],
  Sirdaryo: [
    "Boyovut",
    "Guliston",
    "Mirzaobod",
    "Oqoltin",
    "Sardoba",
    "Sayxunobod",
    "Sirdaryo",
    "Xovos",
  ],
  Xorazm: [
    "Bog'ot",
    "Gurlan",
    "Hazorasp",
    "Xiva",
    "Ko'hna Urganch",
    "Pitnak",
    "Shovot",
    "Urganch",
    "Yangiariq",
    "Yangibozor",
  ],
  "Qoraqalpog'iston": [
    "Amudaryo",
    "Beruniy",
    "Chimboy",
    "Ellikkala",
    "Kegeyli",
    "Mo'ynoq",
    "Nukus",
    "Qanlikol",
    "Qorao'zak",
    "Shumanay",
    "Taxiatosh",
    "To'rtko'l",
    "Xo'jayli",
  ],
};

/** Region names in the order the pickers show them. */
export const UZ_REGION_NAMES: string[] = Object.keys(UZ_DISTRICTS);

/** The districts of `region`, or an empty list for an unknown/blank region. */
export function districtsFor(region: string | null | undefined): string[] {
  if (!region) return [];
  return UZ_DISTRICTS[region] ?? [];
}

/**
 * Every stored place name that should count as "inside this region".
 *
 * A vacancy can name its region three ways: `jobs.region` (the mobile employer
 * form writes a canonical viloyat), `jobs.district` (likewise), or nothing but
 * a typed `jobs.city` — which in practice is either the region, its capital or
 * one of its districts. A region page that only matched `region = X` would
 * therefore show a fraction of what is actually there.
 */
export function regionMatchValues(region: string): string[] {
  const districts = districtsFor(region);
  const bare = region.replace(/\s+(shahri|viloyati)$/i, "").trim();
  return Array.from(new Set([region, bare, ...districts].filter(Boolean)));
}
