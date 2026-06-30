import type { MetadataRoute } from "next";

import { getAllCompanyIds } from "@/lib/data/companies";
import { getAllJobIds } from "@/lib/data/jobs";
import { routing } from "@/i18n/routing";
import { siteUrl } from "@/lib/seo";

/**
 * Dynamic sitemap: the static pages plus every open job and company, for each
 * locale. Lets Google discover and index the full public surface.
 */
export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const base = siteUrl();
  const [jobIds, companyIds] = await Promise.all([
    getAllJobIds(),
    getAllCompanyIds(),
  ]);

  const entries: MetadataRoute.Sitemap = [];

  for (const locale of routing.locales) {
    const prefix = `${base}/${locale}`;
    entries.push(
      { url: prefix, changeFrequency: "daily", priority: 1 },
      { url: `${prefix}/jobs`, changeFrequency: "hourly", priority: 0.9 },
    );
    for (const id of jobIds) {
      entries.push({
        url: `${prefix}/jobs/${id}`,
        changeFrequency: "daily",
        priority: 0.8,
      });
    }
    for (const id of companyIds) {
      entries.push({
        url: `${prefix}/companies/${id}`,
        changeFrequency: "weekly",
        priority: 0.6,
      });
    }
  }

  return entries;
}
