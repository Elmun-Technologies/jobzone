import "server-only";

import type { AdminList } from "../types";
import { adminReadClient, pageRange, toPage } from "./shared";

export interface AdminReportRow {
  id: number;
  targetType: "job" | "company" | "review";
  targetId: string;
  reason: string;
  details: string | null;
  reporterName: string;
  status: string;
  adminNote: string | null;
  createdAt: string;
  resolvedAt: string | null;
}

export async function getAdminReports(
  filter: "open" | "all",
  page: number,
): Promise<AdminList<AdminReportRow>> {
  const client = await adminReadClient();
  if (!client) return null;
  try {
    const { from, to } = pageRange(page);
    let q = client
      .from("content_reports")
      .select(
        "id, target_type, target_id, reason, details, status, admin_note, created_at, resolved_at, reporter:profiles(full_name)",
      )
      .order("created_at", { ascending: false })
      .range(from, to);
    if (filter === "open") q = q.eq("status", "open");
    const { data, error } = await q;
    if (error) throw error;
    return toPage(
      (data ?? []).map((row) => {
        const r = row as Record<string, unknown>;
        const reporter = (r.reporter as { full_name?: unknown } | null)?.full_name;
        return {
          id: Number(r.id),
          targetType: String(r.target_type) as AdminReportRow["targetType"],
          targetId: String(r.target_id),
          reason: String(r.reason),
          details: r.details ? String(r.details) : null,
          reporterName: String(reporter ?? "—"),
          status: String(r.status),
          adminNote: r.admin_note ? String(r.admin_note) : null,
          createdAt: String(r.created_at ?? ""),
          resolvedAt: r.resolved_at ? String(r.resolved_at) : null,
        };
      }),
    );
  } catch (e) {
    console.error("getAdminReports failed", e);
    return { rows: [], hasNext: false };
  }
}
