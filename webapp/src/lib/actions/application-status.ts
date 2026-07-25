"use server";

import { revalidatePath } from "next/cache";

import { createClient } from "@/lib/supabase/server";

const VALID = [
  "submitted",
  "viewed",
  "shortlisted",
  "interview",
  "offer",
  "rejected",
  "hired",
];

/**
 * Advances an application's status by inserting a history row (the
 * sync_application_status trigger denormalizes current_status — we never write
 * it directly). RLS confines this to the job owner (or the applicant).
 */
export async function setApplicationStatus(
  applicationId: string,
  status: string,
): Promise<{ ok: boolean }> {
  if (!VALID.includes(status)) return { ok: false };
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { ok: false };

  const { error } = await supabase.from("application_status_history").insert({
    application_id: applicationId,
    status,
    changed_by: user.id,
  });
  return { ok: !error };
}

/**
 * The applicant withdraws their own application.
 *
 * Not a status-history insert: 0027 locked direct writes to the job owner, so
 * this goes through the `withdraw_application` definer RPC (0059), which
 * re-checks `applicant_id = auth.uid()` server-side before flipping the status
 * and writing the history row. Mobile has offered this since 0059; the web had
 * no way to take back an application sent by mistake.
 */
export async function withdrawApplication(
  applicationId: string,
  locale: string,
): Promise<{ ok: boolean }> {
  if (!applicationId) return { ok: false };
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { ok: false };

  const { error } = await supabase.rpc("withdraw_application", {
    p_application_id: applicationId,
  });
  if (error) {
    console.error("withdrawApplication failed", error);
    return { ok: false };
  }
  revalidatePath(`/${locale}/account/applications`);
  return { ok: true };
}
