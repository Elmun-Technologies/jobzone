import "server-only";

import { mockAdminCompanies } from "../mock";
import type { AdminCompanyRow, AdminList } from "../types";
import { adminReadClient, pageRange, toPage } from "./shared";
import { sanitizeQuery } from "./users";

export async function getAdminCompanies(
  q: string,
  page: number,
): Promise<AdminList<AdminCompanyRow>> {
  const client = await adminReadClient();
  if (client === "mock") return mockAdminCompanies(q);
  if (!client) return null;
  try {
    const { from, to } = pageRange(page);
    let query = client
      .from("companies")
      .select("id, name, headquarters, is_verified, blocked_at, created_at")
      .order("created_at", { ascending: false })
      .range(from, to);
    const needle = sanitizeQuery(q);
    if (needle) query = query.ilike("name", `%${needle}%`);
    const { data, error } = await query;
    if (error) throw error;
    return toPage(
      (data ?? []).map((row) => {
        const r = row as Record<string, unknown>;
        return {
          id: String(r.id),
          name: String(r.name ?? "—"),
          headquarters: r.headquarters ? String(r.headquarters) : null,
          isVerified: Boolean(r.is_verified),
          blockedAt: r.blocked_at ? String(r.blocked_at) : null,
          createdAt: String(r.created_at ?? ""),
        };
      }),
    );
  } catch (e) {
    console.error("getAdminCompanies failed", e);
    return { rows: [], hasNext: false };
  }
}
