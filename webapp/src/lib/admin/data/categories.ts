import "server-only";

import { mockAdminCategories } from "../mock";
import type { AdminCategoryRow } from "../types";
import { adminReadClient } from "./shared";

/**
 * The full category taxonomy (active + retired), sort-order first — the set
 * is small and bounded (~20 rows), so unlike users/companies/jobs this reader
 * returns everything in one round trip, no pagination.
 */
export async function getAdminCategories(): Promise<AdminCategoryRow[] | null> {
  const client = await adminReadClient();
  if (client === "mock") return mockAdminCategories();
  if (!client) return null;
  try {
    const { data, error } = await client
      .from("job_categories")
      .select("id, name, slug, icon, sort_order, is_active")
      .order("sort_order", { ascending: true })
      .order("name", { ascending: true });
    if (error) throw error;
    return (data ?? []).map((row) => {
      const r = row as Record<string, unknown>;
      return {
        id: String(r.id),
        name: String(r.name ?? ""),
        slug: String(r.slug ?? ""),
        icon: r.icon ? String(r.icon) : null,
        sortOrder: Number(r.sort_order ?? 0),
        isActive: Boolean(r.is_active ?? true),
      };
    });
  } catch (e) {
    console.error("getAdminCategories failed", e);
    return [];
  }
}
