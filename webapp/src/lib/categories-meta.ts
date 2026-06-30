import type { JobCategory } from "@/lib/data/types";

// Maps a job category to a representative emoji for the landing-page grid.
// Matching is keyword-based on the slug + name (lowercased), so it tolerates
// the localized category names seeded in `job_categories` without an exact
// enum. First matching rule wins; unmatched categories fall back to 💼.
const RULES: { match: string[]; emoji: string }[] = [
  { match: ["it", "dastur", "program", "developer", "software"], emoji: "💻" },
  { match: ["sotuv", "savdo", "retail", "sales", "call"], emoji: "🛒" },
  {
    match: ["restoran", "horeca", "kafe", "cafe", "bar", "oshxona"],
    emoji: "🍽️",
  },
  {
    match: ["ishlab chiqarish", "tekstil", "production", "factory", "zavod"],
    emoji: "🏭",
  },
  {
    match: [
      "logistika",
      "transport",
      "ombor",
      "yetkaz",
      "delivery",
      "warehouse",
    ],
    emoji: "🚚",
  },
  {
    match: ["qurilish", "ta'mir", "tamir", "construction", "remont", "servis"],
    emoji: "🏗️",
  },
  { match: ["haydovchi", "driver", "shofyor"], emoji: "🚗" },
  { match: ["qo'riq", "qoriq", "security", "guard", "post"], emoji: "🛡️" },
  {
    match: ["tozalash", "kli ning", "cleaning", "klining", "farrosh"],
    emoji: "🧹",
  },
  { match: ["salon", "go'zal", "gozal", "beauty", "sartarosh"], emoji: "💇" },
  { match: ["qishloq", "agro", "agriculture", "fermer"], emoji: "🌾" },
  {
    match: ["chet el", "foreign", "migrats", "xorij", "aqsh", "usa"],
    emoji: "✈️",
  },
  {
    match: ["ta'lim", "talim", "education", "fan", "o'qituvchi", "oqituvchi"],
    emoji: "📚",
  },
  { match: ["marketing", "media", "pr", "smm", "reklama"], emoji: "📣" },
  { match: ["buxgalter", "moliya", "finance", "audit", "bank"], emoji: "💰" },
  {
    match: ["tibbiyot", "farma", "medical", "health", "shifo", "tibbiy"],
    emoji: "🏥",
  },
  {
    match: ["ma'muriy", "mamuriy", "admin", "hr", "menejment", "ofis"],
    emoji: "📋",
  },
  {
    match: ["enaga", "uy ishchi", "nanny", "household", "tarbiyachi"],
    emoji: "🏠",
  },
  {
    match: ["umumiy ishchi", "general", "worker", "ishchi", "razno"],
    emoji: "👷",
  },
];

const FALLBACK = "💼";

/** Picks a representative emoji for a job category. */
export function categoryEmoji(
  category: Pick<JobCategory, "slug" | "name">,
): string {
  const haystack = `${category.slug} ${category.name}`.toLowerCase();
  for (const rule of RULES) {
    if (rule.match.some((kw) => haystack.includes(kw))) return rule.emoji;
  }
  return FALLBACK;
}
