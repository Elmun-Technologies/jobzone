import "server-only";

import { createClient } from "@/lib/supabase/server";

import { toCategory } from "./mappers";
import { mockCategories, mockJobs } from "./mock";
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
  if (!hasSupabase()) {
    return mockCategories.find((c) => c.slug === slug) ?? null;
  }
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

/** Active job categories. */
export async function getCategories(): Promise<JobCategory[]> {
  if (!hasSupabase()) return mockCategories;
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
  if (!hasSupabase()) {
    return mockCategories
      .map((c) => ({
        ...c,
        count: mockJobs.filter((j) => j.categoryName === c.name).length,
      }))
      .sort((a, b) => b.count - a.count);
  }
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
