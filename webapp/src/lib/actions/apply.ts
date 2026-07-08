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

export interface QuickApplyState {
  ok?: boolean;
  signedOut?: boolean;
  /** No usable résumé yet — the caller routes to the résumé builder. */
  needsResume?: boolean;
  /** The job has required screening (or wants a cover letter) — needs the
   * full form; the caller routes there. */
  needsForm?: boolean;
  duplicate?: boolean;
  error?: boolean;
}

/**
 * One-click apply using the seeker's existing profile as their résumé — no
 * cover letter, no answers. This is the "find a job on the map, apply in one
 * tap" path. It only completes when the application needs nothing typed:
 *  - signed in (else `signedOut`),
 *  - has a résumé for the employer to see (else `needsResume`),
 *  - the job has no REQUIRED screening question and doesn't ask for a cover
 *    letter (else `needsForm` → the full apply form).
 * Everything it can't satisfy is reported, not forced, so the caller can route
 * the seeker to fix it and come back.
 */
export async function quickApply(jobId: string): Promise<QuickApplyState> {
  if (!jobId) return { error: true };

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { signedOut: true };

  // A résumé must exist — an application with an empty profile is useless to
  // the employer. onboarding_complete is the wizard's "résumé is done" flag; a
  // filled name is an acceptable fallback (e.g. Google sign-up carried it).
  const { data: profile } = await supabase
    .from("profiles")
    .select("full_name, onboarding_complete")
    .eq("id", user.id)
    .maybeSingle();
  const p = (profile ?? {}) as {
    full_name?: unknown;
    onboarding_complete?: unknown;
  };
  const hasResume =
    p.onboarding_complete === true ||
    (typeof p.full_name === "string" && p.full_name.trim() !== "");
  if (!hasResume) return { needsResume: true };

  // Required screening / cover-letter → the full form (can't answer here).
  const { data: job } = await supabase
    .from("jobs")
    .select("screening_questions, require_cover_letter")
    .eq("id", jobId)
    .maybeSingle();
  if (!job) return { error: true };
  const j = job as {
    screening_questions?: unknown;
    require_cover_letter?: unknown;
  };
  const questions = Array.isArray(j.screening_questions)
    ? (j.screening_questions as { required?: unknown }[])
    : [];
  const hasRequired = questions.some(
    (q) => q && typeof q === "object" && q.required === true,
  );
  if (hasRequired || j.require_cover_letter === true) {
    return { needsForm: true };
  }

  const { error } = await supabase.from("applications").insert({
    job_id: jobId,
    applicant_id: user.id,
    cover_letter: null,
    answers: {},
  });
  if (error) {
    if (error.code === "23505") return { duplicate: true };
    return { error: true };
  }
  return { ok: true };
}
