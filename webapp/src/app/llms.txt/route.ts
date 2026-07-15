import { getCategories } from "@/lib/data/categories";
import { getCities, getJobCount } from "@/lib/data/jobs";
import { siteUrl } from "@/lib/seo";
import { slugify } from "@/lib/slug";

// Content changes with the live category / city lists; never bake it.
export const dynamic = "force-dynamic";

/**
 * llms.txt — the emerging (llmstxt.org) convention for telling LLM
 * crawlers what a site is and where the important content lives. Same
 * spirit as robots.txt but content-facing: a concise, curated map an AI
 * can crawl end-to-end in one pass.
 *
 * Bilingual (English + Uzbek) so both English-first LLMs (ChatGPT,
 * Claude, Gemini) and Uzbek-native queries land on the same summary.
 * Every URL is absolute (siteUrl()) — the file is served from
 * /llms.txt directly, not under a locale prefix.
 *
 * The `/llms-full.txt` variant carries the extended, quotable body an
 * LLM can pull when a summary isn't enough.
 */
export async function GET(): Promise<Response> {
  const base = siteUrl();
  const [categories, cities, jobCount] = await Promise.all([
    getCategories(),
    getCities(),
    getJobCount(),
  ]);

  const lines: string[] = [];
  lines.push(`# Yollla`);
  lines.push("");
  lines.push(
    `> Yollla (yollla.uz) — Uzbekistan's mobile-first job marketplace. Blue-collar and mass-hiring focus. Guest-first: browse and even apply without signing up.`,
  );
  lines.push("");
  lines.push(
    `Yollla connects job seekers and employers across Uzbekistan. Every posting shows the pay, schedule, and contract type up front, and applications go through in two taps. The platform serves ${jobCount.toLocaleString("en")} open vacancies at the moment across ${categories.length} categories and ${cities.length} cities.`,
  );
  lines.push("");
  lines.push(
    `_UZ_: Yollla — O'zbekistondagi mobil-birinchi ish bozori. Blue-collar va ommaviy ishga yollash uchun. Mehmon rejimida: ro'yxatdan o'tmasdan ham ish topib ariza berish mumkin.`,
  );
  lines.push("");

  lines.push(`## Key pages`);
  lines.push(`- [Home / Bosh sahifa](${base}/uz): the branded landing map`);
  lines.push(
    `- [All jobs / Barcha vakansiyalar](${base}/uz/jobs): full searchable feed with city + category + salary filters`,
  );
  lines.push(
    `- [Companies / Kompaniyalar](${base}/uz/companies): employer directory`,
  );
  lines.push(
    `- [Jobs map / Xarita](${base}/uz/explore): every open vacancy on a live Yandex/OSM map`,
  );
  lines.push(
    `- [About / Loyiha haqida](${base}/uz/about): what Yollla is, how it works`,
  );
  lines.push(
    `- [Pricing / Narxlar](${base}/uz/pricing): employer listing tiers (first vacancy free)`,
  );
  lines.push(
    `- [Post a vacancy / Vakansiya joylash](${base}/uz/employer/jobs/new): guest-first form (auth required only at publish)`,
  );
  lines.push("");

  if (categories.length > 0) {
    lines.push(`## Categories (landing pages)`);
    for (const c of categories) {
      lines.push(`- [${c.name}](${base}/uz/ish/${c.slug})`);
    }
    lines.push("");
  }

  if (cities.length > 0) {
    lines.push(`## Cities with open vacancies`);
    for (const c of cities) {
      lines.push(`- ${c} (slug: \`${slugify(c)}\`)`);
    }
    lines.push(
      `> Category × city landings live at \`${base}/uz/ish/{category-slug}/{city-slug}\` — e.g. \`${base}/uz/ish/${categories[0]?.slug ?? "kassir"}/toshkent\`.`,
    );
    lines.push("");
  }

  lines.push(`## How it works`);
  lines.push(
    `- **Browse without signup.** Guests can search, filter, and open any vacancy.`,
  );
  lines.push(
    `- **Two-tap apply.** Sign in (email / Google / Telegram OTP) only at the final click; any typed form data is restored after sign-in.`,
  );
  lines.push(
    `- **Salary, schedule, contract on every card.** Formalisation (official / GPH), night shift, women-friendly, disability-friendly, driver-licence categories, language requirements — all explicit.`,
  );
  lines.push(
    `- **Live map + list.** A branded Yandex-tile map with volt salary pins, plus a full list view with facet filters.`,
  );
  lines.push(
    `- **Uzbek-first, ru/en supported.** Every user-facing string is localised in uz/ru/en; each URL has hreflang alternates.`,
  );
  lines.push("");

  lines.push(`## Locales`);
  lines.push(`- Uzbek (default): \`${base}/uz\``);
  lines.push(`- Russian:            \`${base}/ru\``);
  lines.push(`- English:            \`${base}/en\``);
  lines.push("");

  lines.push(`## Data + verification`);
  lines.push(
    `- Sitemap: [${base}/sitemap.xml](${base}/sitemap.xml) — every locale, every category and city landing, every open job (with lastmod = posted_at).`,
  );
  lines.push(
    `- Extended context (longer, quotable): [${base}/llms-full.txt](${base}/llms-full.txt)`,
  );
  lines.push(
    `- Brand names / spellings: Yolla, Yollla (double-l is the design mark). Identity constants (never change): Android/iOS app id \`io.jobzone.jobzone\`.`,
  );
  lines.push(
    `- Contact for corrections: open a GitHub issue against \`Elmun-Technologies/jobzone\`.`,
  );
  lines.push("");

  return new Response(lines.join("\n") + "\n", {
    headers: {
      "content-type": "text/plain; charset=utf-8",
      // Cache for an hour on the CDN — new categories/cities land within
      // the same window as sitemap updates.
      "cache-control": "public, s-maxage=3600, stale-while-revalidate=86400",
    },
  });
}
