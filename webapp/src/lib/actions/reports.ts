"use server";

import { createClient } from "@/lib/supabase/server";

export type ReportTargetType = "job" | "company" | "review";
export type ReportReason =
  | "spam"
  | "scam"
  | "misleading"
  | "discrimination"
  | "illegal"
  | "inappropriate"
  | "personal_info"
  | "other";

const REASONS: ReadonlySet<ReportReason> = new Set([
  "spam",
  "scam",
  "misleading",
  "discrimination",
  "illegal",
  "inappropriate",
  "personal_info",
  "other",
]);

const TARGETS: ReadonlySet<ReportTargetType> = new Set([
  "job",
  "company",
  "review",
]);

export interface ReportFormState {
  error?: string;
  ok?: boolean;
}

/**
 * User-content report. Any signed-in user can file a report against a
 * job posting, company page, or worker review — Apple 1.2 requires this
 * in-product path. Server validates enums so the client can only submit
 * the fixed values in `content_reports` CHECK constraints; RLS accepts
 * only reporter_id = auth.uid().
 */
export async function submitReportAction(
  _prev: ReportFormState,
  formData: FormData,
): Promise<ReportFormState> {
  const targetType = String(formData.get("targetType") ?? "");
  const targetId = String(formData.get("targetId") ?? "");
  const reason = String(formData.get("reason") ?? "");
  const details = String(formData.get("details") ?? "").slice(0, 500);

  if (!TARGETS.has(targetType as ReportTargetType)) return { error: "invalid" };
  if (!REASONS.has(reason as ReportReason)) return { error: "invalid" };
  if (!targetId) return { error: "invalid" };

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: "no_session" };

  const { error } = await supabase.from("content_reports").insert({
    reporter_id: user.id,
    target_type: targetType,
    target_id: targetId,
    reason,
    details: details || null,
  });
  if (error) return { error: "unknown" };
  return { ok: true };
}

/** Admin: resolve a report (called from /admin/reports UI). */
export async function resolveReportAction(
  reportId: number,
  status: "reviewed" | "dismissed" | "action_taken",
  note?: string,
): Promise<{ ok: true } | { error: string }> {
  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_resolve_report", {
    p_report: reportId,
    p_status: status,
    p_note: note ?? null,
  });
  if (error) return { error: error.message };
  return { ok: true };
}
