"use server";

import { createClient } from "@/lib/supabase/server";
import type { ResumeDraft } from "@/lib/data/resume";

export interface SaveResumeResult {
  ok?: boolean;
  signedOut?: boolean;
  error?: boolean;
}

const clean = (v: string) => {
  const t = v.trim();
  return t === "" ? null : t;
};

/** Persists the resume wizard to the signed-in user's `profiles` row. */
export async function saveResume(
  draft: ResumeDraft,
): Promise<SaveResumeResult> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { signedOut: true };

  const pay = Number(draft.expectedSalary);
  const { error } = await supabase
    .from("profiles")
    .update({
      full_name: clean(draft.fullName),
      headline: clean(draft.position),
      city: clean(draft.city),
      gender: clean(draft.gender),
      birth_date: clean(draft.birthDate),
      marital_status: clean(draft.maritalStatus),
      experience_level: clean(draft.experienceLevel),
      desired_pay_min: Number.isFinite(pay) && pay > 0 ? pay : null,
      desired_pay_currency: draft.currency === "USD" ? "USD" : "UZS",
      phone: clean(draft.phone),
      onboarding_complete: true,
    })
    .eq("id", user.id);

  if (error) return { error: true };
  return { ok: true };
}
