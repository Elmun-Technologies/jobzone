// Stable, deterministic slug for a city name — lower-case ASCII latin, ʻ→'
// stripped, non-word runs collapsed to a single dash. Used on the SEO landing
// URLs (/uz/ish/kassir/toshkent) where Google needs a canonical text id and
// the source of truth is the free-text `city` field on job postings.
//
// The scheme is purposely simple: it accepts uz Latin ("Toshkent" → "toshkent",
// "Farg'ona" → "fargona"), uz Cyrillic ("Тошкент" → "toshkent" via a small
// translit table), and common ru city names ("Ташкент" → "tashkent" — kept
// separate because Cyrillic sources may pre-transliterate).
export function slugify(input: string): string {
  const t = translit(input.trim().toLowerCase());
  return t
    .replace(/['’ʻʼ]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

const CYR: Record<string, string> = {
  а: "a", б: "b", в: "v", г: "g", д: "d", е: "e", ё: "yo",
  ж: "j", з: "z", и: "i", й: "y", к: "k", л: "l", м: "m",
  н: "n", о: "o", п: "p", р: "r", с: "s", т: "t", у: "u",
  ф: "f", х: "h", ц: "ts", ч: "ch", ш: "sh", щ: "sh",
  ъ: "", ы: "y", ь: "", э: "e", ю: "yu", я: "ya",
  ў: "o", қ: "q", ғ: "g", ҳ: "h",
};

function translit(s: string): string {
  let out = "";
  for (const ch of s) out += CYR[ch] ?? ch;
  return out;
}
