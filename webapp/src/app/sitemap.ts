import type { MetadataRoute } from "next";

import { routing } from "@/i18n/routing";
import { getCategories } from "@/lib/data/categories";
import { getAllCompanyIds } from "@/lib/data/companies";
import { getAllJobsForSitemap, getCities } from "@/lib/data/jobs";
import { siteUrl } from "@/lib/seo";
import { slugify } from "@/lib/slug";

/**
 * Full-graph sitemap: every public page × every locale, with hreflang
 * `alternates.languages` on each entry so Google reads all three copies as
 * one canonical piece of content and stops treating localized siblings as
 * duplicates.
 *
 * Contents per canonical URL:
 *
 * - Static pages   — /, /jobs, /companies, /explore, /about, /pricing
 * - Landing pages  — /ish/[category] × N categories (long-tail queries)
 *                  — /ish/[category]/[city] × N × M (deepest long-tail)
 * - Every open job — /jobs/[id] with `lastModified` from `postedAt`
 * - Every company  — /companies/[id]
 *
 * All URLs use the origin returned by siteUrl() (defaults to
 * https://www.yollla.uz); never a Vercel preview host. Bounded per data
 * loader — the current caps (1 000 jobs, all cities/categories/companies)
 * are far under the 50 000 URL sitemap-spec limit.
 */
export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const base = siteUrl();
  const [categories, cities, jobs, companyIds] = await Promise.all([
    getCategories(),
    getCities(),
    getAllJobsForSitemap(),
    getAllCompanyIds(),
  ]);

  const entries: MetadataRoute.Sitemap = [];

  // Emit one canonical entry per (path, defaultLocale) and pack the other
  // locales into alternates.languages — Google prefers this shape over three
  // separate <url> entries per path, and it keeps the sitemap compact.
  const push = (
    path: string,
    opts: {
      changeFrequency?: MetadataRoute.Sitemap[number]["changeFrequency"];
      priority?: number;
      lastModified?: string | Date;
    } = {},
  ) => {
    const languages: Record<string, string> = {};
    for (const loc of routing.locales) {
      languages[loc] = `${base}/${loc}${path}`;
    }
    entries.push({
      url: `${base}/${routing.defaultLocale}${path}`,
      changeFrequency: opts.changeFrequency,
      priority: opts.priority,
      lastModified: opts.lastModified,
      alternates: { languages },
    });
  };

  // Static pages — priority reflects business importance for organic search.
  push("", { changeFrequency: "daily", priority: 1 });
  push("/jobs", { changeFrequency: "hourly", priority: 0.9 });
  push("/explore", { changeFrequency: "hourly", priority: 0.8 });
  push("/companies", { changeFrequency: "weekly", priority: 0.7 });
  push("/about", { changeFrequency: "monthly", priority: 0.5 });
  push("/pricing", { changeFrequency: "monthly", priority: 0.5 });

  // SEO landing pages — every category, then category × city. These are the
  // long-tail funnels ("kassir ishi", "toshkentda kassir ishi") and matter
  // most for organic acquisition, so priority sits between static and jobs.
  for (const cat of categories) {
    push(`/ish/${cat.slug}`, {
      changeFrequency: "daily",
      priority: 0.8,
    });
    for (const city of cities) {
      push(`/ish/${cat.slug}/${slugify(city)}`, {
        changeFrequency: "daily",
        priority: 0.75,
      });
    }
  }

  // Individual open jobs — high priority because they carry JobPosting
  // schema (Google Jobs eligibility) and lastMod tracks postedAt.
  for (const job of jobs) {
    push(`/jobs/${job.id}`, {
      changeFrequency: "daily",
      priority: 0.7,
      lastModified: job.postedAt ?? undefined,
    });
  }

  // Company pages — thin content compared with jobs; priority tuned down.
  for (const id of companyIds) {
    push(`/companies/${id}`, {
      changeFrequency: "weekly",
      priority: 0.5,
    });
  }

  return entries;
}
