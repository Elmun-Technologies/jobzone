"use server";

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
