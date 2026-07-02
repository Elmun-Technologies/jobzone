"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { hasSupabase } from "@/lib/data/supabase-env";
import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";

/**
 * Moderation actions. Every mutation is an `is_admin()`-gated SECURITY DEFINER
 * RPC (0016/0038) called with the user's own cookie client, so the DB
 * re-checks the actor and writes the audit row — the panel never mutates rows
 * directly. In mock mode (no Supabase env) actions are demo no-ops. On RPC
 * failure the admin lands back on the page with ?notice=err.
 */

function field(formData: FormData, name: string): string {
  const v = formData.get(name);
  return typeof v === "string" ? v.trim() : "";
}

function backPath(formData: FormData, page: string): string {
  const locale = field(formData, "locale") || "uz";
  return `/${locale}/admin/${page}`;
}

async function runAdminRpc(
  fn: string,
  args: Record<string, unknown>,
  backTo: string,
): Promise<void> {
  if (!hasSupabase()) {
    revalidatePath(backTo);
    return;
  }
  const supabase = await createClient();
  const { error } = await supabase.rpc(fn, args);
  if (error) {
    console.error(`${fn} failed`, error);
    redirect(`${backTo}?notice=err`);
  }
  revalidatePath(backTo);
}

export async function setJobBlocked(formData: FormData): Promise<void> {
  const backTo = backPath(formData, "jobs");
  const id = field(formData, "id");
  if (!id) redirect(`${backTo}?notice=err`);
  await runAdminRpc(
    "admin_set_job_blocked",
    {
      p_job: id,
      p_blocked: field(formData, "blocked") === "1",
      p_reason: field(formData, "reason") || null,
    },
    backTo,
  );
}

export async function setCompanyBlocked(formData: FormData): Promise<void> {
  const backTo = backPath(formData, "companies");
  const id = field(formData, "id");
  if (!id) redirect(`${backTo}?notice=err`);
  await runAdminRpc(
    "admin_set_company_blocked",
    {
      p_company: id,
      p_blocked: field(formData, "blocked") === "1",
      p_reason: field(formData, "reason") || null,
    },
    backTo,
  );
}

export async function setProfileSuspended(formData: FormData): Promise<void> {
  const backTo = backPath(formData, "users");
  const id = field(formData, "id");
  const suspended = field(formData, "suspended") === "1";
  if (!id) redirect(`${backTo}?notice=err`);
  await runAdminRpc(
    "admin_set_profile_suspended",
    {
      p_profile: id,
      p_suspended: suspended,
      p_reason: field(formData, "reason") || null,
    },
    backTo,
  );
  // Best-effort auth ban so a suspended account can't sign in at all. Needs
  // the service key; without it the profile flag still stands (RLS-guarded).
  const admin = createAdminClient();
  if (admin) {
    try {
      await admin.auth.admin.updateUserById(id, {
        ban_duration: suspended ? "87600h" : "none",
      });
    } catch (e) {
      console.error("auth ban update failed", e);
    }
  }
}

const COMPANY_VERIFY_METHODS = new Set(["legal_entity", "licensed_agency"]);

export async function verifyCompany(formData: FormData): Promise<void> {
  const backTo = backPath(formData, "companies");
  const id = field(formData, "id");
  const method = field(formData, "method");
  if (!id || !COMPANY_VERIFY_METHODS.has(method)) redirect(`${backTo}?notice=err`);
  await runAdminRpc(
    "admin_set_company_verification",
    { p_company: id, p_method: method },
    backTo,
  );
}

const WORKER_VERIFY_METHODS = new Set(["id_document", "manual"]);

export async function verifyWorker(formData: FormData): Promise<void> {
  const backTo = backPath(formData, "users");
  const id = field(formData, "id");
  const method = field(formData, "method");
  if (!id || !WORKER_VERIFY_METHODS.has(method)) redirect(`${backTo}?notice=err`);
  await runAdminRpc(
    "admin_set_worker_verification",
    { p_profile: id, p_method: method },
    backTo,
  );
}

export async function setReviewHidden(formData: FormData): Promise<void> {
  const backTo = backPath(formData, "reviews");
  const id = field(formData, "id");
  const kind = field(formData, "kind");
  if (!id || (kind !== "company" && kind !== "worker")) {
    redirect(`${backTo}?notice=err`);
  }
  await runAdminRpc(
    kind === "company"
      ? "admin_set_company_review_hidden"
      : "admin_set_worker_review_hidden",
    {
      p_review: id,
      p_hidden: field(formData, "hidden") === "1",
      p_reason: field(formData, "reason") || null,
    },
    backTo,
  );
}
