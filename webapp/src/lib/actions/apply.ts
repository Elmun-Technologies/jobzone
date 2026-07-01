"use server";

import { redirect } from "next/navigation";

import { createClient } from "@/lib/supabase/server";

export interface ApplyState {
  error?: string;
  signedOut?: boolean;
}

/**
 * Submits a job application for the signed-in user. Screening answers arrive as
 * `answer:<questionId>` fields. The DB triggers seed the status timeline and
 * bump applicants_count; current_status defaults to 'submitted'.
 *
 * Guest-first: a visitor can fill this out without being signed in. If they
 * aren't authenticated at submit-time, this returns `signedOut` instead of
 * redirecting, so the caller can stash the filled form and send them to sign
 * in without losing the cover letter / answers.
 */
export async function applyToJob(
  _prev: ApplyState,
  formData: FormData,
): Promise<ApplyState> {
  const jobId = (formData.get("jobId") ?? "").toString();
  const locale = (formData.get("locale") ?? "uz").toString();
  const coverLetter = (formData.get("coverLetter") ?? "").toString().trim();
  if (!jobId) return { error: "unknown" };

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { signedOut: true };

  const answers: Record<string, string> = {};
  for (const [key, value] of formData.entries()) {
    if (key.startsWith("answer:")) {
      answers[key.slice("answer:".length)] = value.toString();
    }
  }

  const { error } = await supabase.from("applications").insert({
    job_id: jobId,
    applicant_id: user.id,
    cover_letter: coverLetter || null,
    answers,
  });

  if (error) {
    if (error.code === "23505") return { error: "duplicate" };
    return { error: "unknown" };
  }

  redirect(`/${locale}/account/applications?applied=1`);
}
