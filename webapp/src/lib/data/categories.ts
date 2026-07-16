import "server-only";

import { createClient } from "@/lib/supabase/server";

import { toCategory } from "./mappers";
import { hasSupabase } from "./supabase-env";
import type { JobCategory } from "./types";

export interface CategoryWithCount extends JobCategory {
  /** Open vacancies in this category. */
  count: number;
}

/** Find one active category by its slug — the URL segment used on the
 * /[locale]/ish/[category] landing pages. Returns null when there is no
 * match so the caller can 404 cleanly. */
export async function getCategoryBySlug(
  slug: string,
): Promise<JobCategory | null> {
  // Online-only: without a configured backend there is nothing to show.
  if (!hasSupabase()) return null;
  try {
    const supabase = await createClient();
    const { data, error } = await supabase
      .from("job_categories")
      .select("id, slug, name")
      .eq("is_active", true)
      .eq("slug", slug)
      .maybeSingle();
    if (error) throw error;
    return data ? toCategory(data) : null;
  } catch (e) {
    console.error("getCategoryBySlug failed", e);
    return null;
  }
}

/**
 * Look up a category by a retired slug (0069 job_category_slug_history).
 * Returns the CURRENT slug + name of the category the retired slug used to
 * point at, or null if it was never used. Powers the 301 redirect on
 * /ish/[category]: without it every renamed category 404s and drops its
 * SEO history.
 */
export async function getCategoryByHistoricalSlug(
  slug: string,
): Promise<JobCategory | null> {
  if (!hasSupabase()) return null;
  try {
    const supabase = await createClient();
    const { data, error } = await supabase
      .from("job_category_slug_history")
      .select("category_id, job_categories!inner(id, slug, name, is_active)")
      .eq("slug", slug)
      .eq("job_categories.is_active", true)
      .maybeSingle();
    if (error) throw error;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const cat = (data as any)?.job_categories;
    return cat ? toCategory(cat) : null;
  } catch (e) {
    console.error("getCategoryByHistoricalSlug failed", e);
    return null;
  }
}

/** Active job categories. */
export async function getCategories(): Promise<JobCategory[]> {
  if (!hasSupabase()) return [];
  try {
    const supabase = await createClient();
    const { data, error } = await supabase
      .from("job_categories")
      .select("id, slug, name")
      .eq("is_active", true)
      .order("sort_order", { ascending: true })
      .order("name", { ascending: true });
    if (error) throw error;
    return (data ?? []).map(toCategory);
  } catch (e) {
    console.error("getCategories failed", e);
    return [];
  }
}

/**
 * Categories with their open-vacancy counts, busiest first — backs the
 * landing-page category grid. Counts are exact (one head-count per category;
 * the category set is small and bounded).
 */
export async function getCategoriesWithCounts(): Promise<CategoryWithCount[]> {
  if (!hasSupabase()) return [];
  try {
    const supabase = await createClient();
    const { data, error } = await supabase
      .from("job_categories")
      .select("id, slug, name")
      .eq("is_active", true)
      .order("sort_order", { ascending: true })
      .order("name", { ascending: true });
    if (error) throw error;
    const cats = (data ?? []).map(toCategory);

    const withCounts = await Promise.all(
      cats.map(async (c) => {
        const { count } = await supabase
          .from("job_feed")
          .select("id", { count: "exact", head: true })
          .eq("status", "open")
          .eq("category_name", c.name);
        return { ...c, count: count ?? 0 };
      }),
    );
    return withCounts.sort((a, b) => b.count - a.count);
  } catch (e) {
    console.error("getCategoriesWithCounts failed", e);
    return [];
  }
}
