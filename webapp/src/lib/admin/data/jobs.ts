import "server-only";

import type { AdminJobRow, AdminList } from "../types";
import { adminReadClient, pageRange, toPage } from "./shared";
import { sanitizeQuery } from "./users";

export async function getAdminJobs(
  q: string,
  page: number,
): Promise<AdminList<AdminJobRow>> {
  const client = await adminReadClient();
  if (!client) return null;
  try {
    const { from, to } = pageRange(page);
    let query = client
      .from("jobs")
      .select(
        "id, title, city, status, applicants_count, blocked_at, created_at, companies(name)",
      )
      .order("created_at", { ascending: false })
      .range(from, to);
    const needle = sanitizeQuery(q);
    if (needle) query = query.ilike("title", `%${needle}%`);
    const { data, error } = await query;
    if (error) throw error;
    return toPage(
      (data ?? []).map((row) => {
        const r = row as Record<string, unknown>;
        const company = r.companies as { name?: unknown } | null;
        return {
          id: String(r.id),
          title: String(r.title ?? "—"),
          companyName: String(company?.name ?? "—"),
          city: r.city ? String(r.city) : null,
          status: String(r.status ?? "open"),
          applicantsCount: Number(r.applicants_count ?? 0),
          blockedAt: r.blocked_at ? String(r.blocked_at) : null,
          createdAt: String(r.created_at ?? ""),
        };
      }),
    );
  } catch (e) {
    console.error("getAdminJobs failed", e);
    return { rows: [], hasNext: false };
  }
}
