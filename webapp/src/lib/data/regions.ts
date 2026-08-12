import "server-only";

import { unstable_cache } from "next/cache";

import { createPublicClient } from "@/lib/supabase/server";
import { regionMatchValues, UZ_REGION_NAMES } from "@/lib/uz-districts";

import { toJob } from "./mappers";
import { hasSupabase } from "./supabase-env";
import type { Job } from "./types";

/**
 * Region landing pages: "all the work in this viloyat", which is how people
 * actually search ("Andijonda ish", "работа в Фергане") and the one shape of
 * long-tail page the local job sites all have and we did not.
 *
 * Everything here reads the anon/public client through `unstable_cache`, not
 * the request-scoped one: these pages are identical for every visitor, are the
 * pages search engines hit hardest, and each was otherwise a fan-out of live
 * Supabase round-trips on a cold serverless function.
 */

// Same 5-minute window (and the same "jobs" tag) as the category counts, so a
// publish or a close flushes the region pages in the same breath.
const REVALIDATE = 300;

export interface RegionCategoryCount {
  slug: string;
  name: string;
  count: number;
}

export interface RegionSnapshot {
  /** Canonical viloyat name, as stored on `jobs.region`. */
  region: string;
  /** Open vacancies anywhere in the region. */
  total: number;
  /** Per-category tallies inside the region, busiest first, zeroes dropped. */
  categories: RegionCategoryCount[];
}

/** PostgREST `in.(…)` list — values are quoted, embedded quotes dropped. */
function inList(values: string[]): string {
  return values.map((v) => `"${v.replace(/"/g, "")}"`).join(",");
}

/** `region`, `district` or a typed `city` naming the place — see regionMatchValues. */
function regionFilter(region: string): string {
  const list = inList(regionMatchValues(region));
  return `region.in.(${list}),district.in.(${list}),city.in.(${list})`;
}

const _getRegionSnapshot = unstable_cache(
  async (region: string): Promise<RegionSnapshot> => {
    const supabase = createPublicClient();
    const [{ data: rows, error }, { data: cats, error: catErr }] =
      await Promise.all([
        // One pass over the region's open jobs, tallied locally — the same
        // trade the global category counts make, for the same reason (a
        // count-per-category fan-out is 20+ cross-region round-trips).
        supabase
          .from("job_feed")
          .select("category_name")
          .eq("status", "open")
          .or(regionFilter(region))
          .limit(20000),
        supabase
          .from("job_categories")
          .select("slug, name")
          .eq("is_active", true),
      ]);
    if (error) throw error;
    if (catErr) throw catErr;

    const tally = new Map<string, number>();
    for (const row of rows ?? []) {
      const name = (row as { category_name: string | null }).category_name;
      if (name) tally.set(name, (tally.get(name) ?? 0) + 1);
    }
    const categories = ((cats ?? []) as { slug: string; name: string }[])
      .map((c) => ({
        slug: c.slug,
        name: c.name,
        count: tally.get(c.name) ?? 0,
      }))
      .filter((c) => c.count > 0)
      .sort((a, b) => b.count - a.count);

    return { region, total: rows?.length ?? 0, categories };
  },
  ["region-snapshot"],
  { tags: ["jobs", "categories"], revalidate: REVALIDATE },
);

const _getRegionJobs = unstable_cache(
  async (region: string, limit: number): Promise<Job[]> => {
    const supabase = createPublicClient();
    const { data, error } = await supabase
      .from("job_feed")
      .select("*")
      .eq("status", "open")
      .or(regionFilter(region))
      .order("boost_active", { ascending: false })
      .order("posted_at", { ascending: false })
      .limit(limit);
    if (error) throw error;
    return (data ?? []).map(toJob);
  },
  ["region-jobs"],
  { tags: ["jobs"], revalidate: REVALIDATE },
);

/** Totals + per-category counts for a region's landing page. */
export async function getRegionSnapshot(
  region: string,
): Promise<RegionSnapshot> {
  const empty: RegionSnapshot = { region, total: 0, categories: [] };
  if (!hasSupabase()) return empty;
  try {
    return await _getRegionSnapshot(region);
  } catch (e) {
    console.error("getRegionSnapshot failed", e);
    return empty;
  }
}

/** The newest open vacancies in a region (boosted first). */
export async function getRegionJobs(
  region: string,
  limit = 24,
): Promise<Job[]> {
  if (!hasSupabase()) return [];
  try {
    return await _getRegionJobs(region, limit);
  } catch (e) {
    console.error("getRegionJobs failed", e);
    return [];
  }
}

/** Region names for the footer and the sitemap, in display order. */
export function regionNames(): string[] {
  return UZ_REGION_NAMES;
}

export interface MarketplaceStats {
  /** Open vacancies across the country. */
  openJobs: number;
  /** Companies with at least one open vacancy — employers actually hiring. */
  hiringCompanies: number;
  /** Regions with at least one open vacancy. */
  activeRegions: number;
}

const _getMarketplaceStats = unstable_cache(
  async (): Promise<MarketplaceStats> => {
    const supabase = createPublicClient();
    // One pass over the open feed: three numbers from the same rows rather
    // than three count queries. The employer page shows these as its only
    // "proof" figures, so they must be the real feed, not a claim.
    const { data, error } = await supabase
      .from("job_feed")
      .select("company_id, region, city")
      .eq("status", "open")
      .limit(20000);
    if (error) throw error;
    const companies = new Set<string>();
    const regions = new Set<string>();
    for (const row of data ?? []) {
      const r = row as { company_id?: string; region?: string; city?: string };
      if (r.company_id) companies.add(r.company_id);
      const place = r.region ?? r.city;
      if (place) regions.add(place.toLowerCase().trim());
    }
    return {
      openJobs: data?.length ?? 0,
      hiringCompanies: companies.size,
      activeRegions: regions.size,
    };
  },
  ["marketplace-stats"],
  { tags: ["jobs"], revalidate: REVALIDATE },
);

/** Live totals for the employer page's proof figures. */
export async function getMarketplaceStats(): Promise<MarketplaceStats> {
  const empty: MarketplaceStats = {
    openJobs: 0,
    hiringCompanies: 0,
    activeRegions: 0,
  };
  if (!hasSupabase()) return empty;
  try {
    return await _getMarketplaceStats();
  } catch (e) {
    console.error("getMarketplaceStats failed", e);
    return empty;
  }
}
