"use server";

import { redirect } from "next/navigation";

import { createClient } from "@/lib/supabase/server";

export interface ApplyState {
  error?: string;
}

/**
 * Submits a job application for the signed-in user. Screening answers arrive as
 * `answer:<questionId>` fields. The DB triggers seed the status timeline and
 * bump applicants_count; current_status defaults to 'submitted'.
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
  if (!user) redirect(`/${locale}/sign-in`);

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
