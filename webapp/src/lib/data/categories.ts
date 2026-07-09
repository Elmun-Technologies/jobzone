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
