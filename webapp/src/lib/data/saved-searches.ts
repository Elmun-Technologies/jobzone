import "server-only";

import { createClient } from "@/lib/supabase/server";

import { hasSupabase } from "./supabase-env";

export interface SavedSearch {
  id: string;
  name: string;
  keywords: string | null;
  city: string | null;
  createdAt: string | null;
}

/**
 * The signed-in seeker's saved searches (newest first). RLS confines the read
 * to the owner, so a missing backend or any error degrades to an empty list.
 */
export async function getSavedSearches(): Promise<SavedSearch[]> {
  if (!hasSupabase()) return [];
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return [];
    const { data, error } = await supabase
      .from("saved_searches")
      .select("id, name, keywords, city, created_at")
      .order("created_at", { ascending: false });
    if (error) throw error;
    return (data ?? []).map((r) => {
      const row = r as Record<string, unknown>;
      return {
        id: String(row.id),
        name: String(row.name ?? ""),
        keywords: typeof row.keywords === "string" ? row.keywords : null,
        city: typeof row.city === "string" ? row.city : null,
        createdAt: typeof row.created_at === "string" ? row.created_at : null,
      };
    });
  } catch (e) {
    console.error("getSavedSearches failed", e);
    return [];
  }
}
