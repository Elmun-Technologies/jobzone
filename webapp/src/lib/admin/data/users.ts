import "server-only";

import type { AdminList, AdminUserRow } from "../types";
import { adminReadClient, pageRange, toPage } from "./shared";

/** ilike-safe: strip PostgREST or() separators from the raw query. */
export function sanitizeQuery(q: string): string {
  return q.replace(/[,()%]/g, " ").trim();
}

export async function getAdminUsers(
  q: string,
  page: number,
): Promise<AdminList<AdminUserRow>> {
  const client = await adminReadClient();
  if (!client) return null;
  try {
    const { from, to } = pageRange(page);
    let query = client
      .from("profiles")
      .select(
        "id, full_name, phone, email, city, role, created_at, suspended_at, worker_verified_at, is_admin",
      )
      .order("created_at", { ascending: false })
      .range(from, to);
    const needle = sanitizeQuery(q);
    if (needle) {
      query = query.or(
        `full_name.ilike.%${needle}%,phone.ilike.%${needle}%,email.ilike.%${needle}%`,
      );
    }
    const { data, error } = await query;
    if (error) throw error;
    return toPage(
      (data ?? []).map((row) => {
        const r = row as Record<string, unknown>;
        return {
          id: String(r.id),
          fullName: String(r.full_name ?? "—"),
          phone: r.phone ? String(r.phone) : null,
          email: r.email ? String(r.email) : null,
          city: r.city ? String(r.city) : null,
          role: String(r.role ?? "job_seeker"),
          createdAt: String(r.created_at ?? ""),
          suspendedAt: r.suspended_at ? String(r.suspended_at) : null,
          workerVerifiedAt: r.worker_verified_at
            ? String(r.worker_verified_at)
            : null,
          isAdmin: Boolean(r.is_admin ?? false),
        };
      }),
    );
  } catch (e) {
    console.error("getAdminUsers failed", e);
    return { rows: [], hasNext: false };
  }
}
