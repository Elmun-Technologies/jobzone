import "server-only";

import type { AdminAuditRow, AdminList } from "../types";
import { adminReadClient, pageRange, toPage } from "./shared";

export async function getAdminAudit(
  page: number,
): Promise<AdminList<AdminAuditRow>> {
  const client = await adminReadClient();
  if (!client) return null;
  try {
    const { from, to } = pageRange(page);
    const { data, error } = await client
      .from("admin_audit_log")
      .select(
        "id, action, target_type, target_id, meta, created_at, actor:profiles(full_name)",
      )
      .order("created_at", { ascending: false })
      .range(from, to);
    if (error) throw error;
    return toPage(
      (data ?? []).map((row) => {
        const r = row as Record<string, unknown>;
        const actor = (r.actor as { full_name?: unknown } | null)?.full_name;
        return {
          id: Number(r.id),
          actorName: String(actor ?? "—"),
          action: String(r.action ?? ""),
          targetType: r.target_type ? String(r.target_type) : null,
          targetId: r.target_id ? String(r.target_id) : null,
          meta: (r.meta as Record<string, unknown>) ?? {},
          createdAt: String(r.created_at ?? ""),
        };
      }),
    );
  } catch (e) {
    console.error("getAdminAudit failed", e);
    return { rows: [], hasNext: false };
  }
}
