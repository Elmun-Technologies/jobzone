// Curated blue-collar / mass-hiring professions for the post-a-job title
// autocomplete, each mapped to a `job_categories.slug`. Used to (a) suggest a
// title as the employer types and (b) auto-pick the category from the title.
// Labels are Uzbek (the product's first language) — the field is free-text, so
// this is only a helper, never a constraint.

export interface Profession {
  label: string;
  slug: string;
}

export const PROFESSIONS: Profession[] = [
  // Retail & Sales
  { label: "Sotuvchi", slug: "retail" },
  { label: "Sotuvchi-konsultant", slug: "retail" },
  { label: "Kassir", slug: "retail" },
  { label: "Sotuv menejeri", slug: "retail" },
  { label: "Merchandayzer", slug: "retail" },
  { label: "Do'kon administratori", slug: "retail" },
  { label: "Marketolog", slug: "retail" },
  { label: "SMM menejer", slug: "retail" },
  // Restaurants & Hospitality
  { label: "Ofitsiant", slug: "horeca" },
  { label: "Oshpaz", slug: "horeca" },
  { label: "Oshpaz yordamchisi", slug: "horeca" },
  { label: "Barista", slug: "horeca" },
  { label: "Barmen", slug: "horeca" },
  { label: "Qandolatchi", slug: "horeca" },
  { label: "Novvoy", slug: "horeca" },
  { label: "Qassob", slug: "horeca" },
  { label: "Xostes", slug: "horeca" },
  { label: "Idish yuvuvchi", slug: "horeca" },
  // Logistics & Delivery
  { label: "Kuryer", slug: "logistics" },
  { label: "Yetkazib beruvchi", slug: "logistics" },
  { label: "Ekspeditor", slug: "logistics" },
  { label: "Logist", slug: "logistics" },
  // Drivers
  { label: "Haydovchi", slug: "driver" },
  { label: "Taksi haydovchisi", slug: "driver" },
  { label: "Yuk mashina haydovchisi", slug: "driver" },
  { label: "Ekskavatorchi", slug: "driver" },
  // Warehouse
  { label: "Omborchi", slug: "warehouse" },
  { label: "Yuk tashuvchi", slug: "warehouse" },
  { label: "Komplektovshchik", slug: "warehouse" },
  { label: "Ombor operatori", slug: "warehouse" },
  // Construction
  { label: "Quruvchi", slug: "construction" },
  { label: "Elektrik", slug: "construction" },
  { label: "Santexnik", slug: "construction" },
  { label: "Payvandchi", slug: "construction" },
  { label: "Suvoqchi", slug: "construction" },
  { label: "Bo'yoqchi", slug: "construction" },
  { label: "G'isht teruvchi", slug: "construction" },
  { label: "Beton quyuvchi", slug: "construction" },
  { label: "Plitka teruvchi", slug: "construction" },
  { label: "Armaturachi", slug: "construction" },
  // Cleaning
  { label: "Farrosh", slug: "cleaning" },
  { label: "Tozalovchi", slug: "cleaning" },
  { label: "Xizmatkor", slug: "cleaning" },
  { label: "Oyna yuvuvchi", slug: "cleaning" },
  // Security
  { label: "Qorovul", slug: "security" },
  { label: "Xavfsizlik xodimi", slug: "security" },
  { label: "Nazoratchi", slug: "security" },
  // Beauty & Salon
  { label: "Sartarosh", slug: "beauty" },
  { label: "Kosmetolog", slug: "beauty" },
  { label: "Manikyurchi", slug: "beauty" },
  { label: "Vizajist", slug: "beauty" },
  { label: "Massajchi", slug: "beauty" },
  { label: "Stilist", slug: "beauty" },
  // Manufacturing
  { label: "Tikuvchi", slug: "manufacturing" },
  { label: "Stanokchi", slug: "manufacturing" },
  { label: "Ishlab chiqarish operatori", slug: "manufacturing" },
  { label: "Yig'uvchi", slug: "manufacturing" },
  { label: "Duradgor", slug: "manufacturing" },
  // Agriculture
  { label: "Bog'bon", slug: "agriculture" },
  { label: "Fermer", slug: "agriculture" },
  { label: "Dala ishchisi", slug: "agriculture" },
  { label: "Chorvador", slug: "agriculture" },
  { label: "Traktorchi", slug: "agriculture" },
];

/** Normalize a title for matching: lowercase, drop accents + apostrophes. */
function norm(s: string): string {
  return s
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/['`ʻʼʹ‘’]/g, "")
    .trim();
}

/**
 * Best-guess `job_categories.slug` for a typed title, or null. Matches a
 * profession by exact/prefix, then by the title containing a profession word.
 */
export function suggestCategorySlug(title: string): string | null {
  const n = norm(title);
  if (n.length < 3) return null;
  const normed = PROFESSIONS.map((p) => ({ n: norm(p.label), slug: p.slug }));
  // 1) The title is (or starts with) a known profession.
  for (const p of normed) {
    if (n === p.n || n.startsWith(p.n + " ")) return p.slug;
  }
  // 2) The title contains a known profession as a word.
  for (const p of normed) {
    if (n.includes(p.n)) return p.slug;
  }
  return null;
}
