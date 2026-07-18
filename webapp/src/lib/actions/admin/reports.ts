"use server";

import { revalidatePath } from "next/cache";

import { createClient } from "@/lib/supabase/server";

/**
 * Resolve a content report (admin RPC — audited server-side by
 * `admin_resolve_report()` which admin_audit()'s every transition).
 */
export async function resolveReport(
  reportId: number,
  status: "reviewed" | "dismissed" | "action_taken",
  note?: string,
): Promise<{ ok: true } | { ok: false; error: string }> {
  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_resolve_report", {
    p_report: reportId,
    p_status: status,
    p_note: note ?? null,
  });
  if (error) return { ok: false, error: error.message };
  // Refresh the admin queue after resolution.
  revalidatePath("/admin/reports", "page");
  return { ok: true };
}
