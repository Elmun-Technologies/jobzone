import "server-only";

import type { SupabaseClient } from "@supabase/supabase-js";

import { isAdminUser } from "@/lib/auth/admin-role";
import { getCurrentUser } from "@/lib/auth/user";
import { hasSupabase } from "@/lib/data/supabase-env";
import { createAdminClient } from "@/lib/supabase/admin";

export const ADMIN_PAGE_SIZE = 20;

/**
 * Entry point of every privileged admin reader. Two outcomes:
 * - null    — Supabase env or SUPABASE_SERVICE_ROLE_KEY missing: pages show
 *             the config hint (the panel is online-only, no demo fixtures);
 * - client  — the service-role client, only ever handed out after re-checking
 *             that the current session is an admin (defense-in-depth on top of
 *             the page's requireAdmin()).
 */
export async function adminReadClient(): Promise<SupabaseClient | null> {
  if (!hasSupabase()) return null;
  const user = await getCurrentUser();
  if (!isAdminUser(user)) throw new Error("admin only");
  return createAdminClient();
}

/** 1-based page -> supabase range; asks for one extra row to learn hasNext. */
export function pageRange(page: number): { from: number; to: number } {
  const from = (Math.max(1, page) - 1) * ADMIN_PAGE_SIZE;
  return { from, to: from + ADMIN_PAGE_SIZE };
}

/** Trims the probe row and reports whether a next page exists. */
export function toPage<T>(rows: T[]): { rows: T[]; hasNext: boolean } {
  return {
    rows: rows.slice(0, ADMIN_PAGE_SIZE),
    hasNext: rows.length > ADMIN_PAGE_SIZE,
  };
}
