import "server-only";

import { createClient } from "@/lib/supabase/server";

import { toCategory } from "./mappers";
import { mockCategories } from "./mock";
import { hasSupabase } from "./supabase-env";
import type { JobCategory } from "./types";

/** Active job categories. */
export async function getCategories(): Promise<JobCategory[]> {
  if (!hasSupabase()) return mockCategories;
  try {
    const supabase = await createClient();
    const { data, error } = await supabase
      .from("job_categories")
      .select("id, slug, name")
      .order("name", { ascending: true });
    if (error) throw error;
    return (data ?? []).map(toCategory);
  } catch (e) {
    console.error("getCategories failed", e);
    return [];
  }
}
