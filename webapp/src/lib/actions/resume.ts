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

/**
 * Replaces a profile's rows in a résumé sub-table (delete-then-insert) and
 * reports whether BOTH steps actually succeeded — used to be fire-and-forget,
 * so a failed insert (after the delete already went through) silently lost the
 * seeker's section while the wizard still reported "saved."
 */
async function replaceRows(
  supabase: Awaited<ReturnType<typeof createClient>>,
  table: string,
  profileId: string,
  rows: Record<string, unknown>[],
): Promise<boolean> {
  const del = await supabase.from(table).delete().eq("profile_id", profileId);
  if (del.error) return false;
  if (rows.length === 0) return true;
  const ins = await supabase.from(table).insert(rows);
  return !ins.error;
}

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
      email: clean(draft.email),
      languages: draft.languages ?? {},
      onboarding_complete: true,
    })
    .eq("id", user.id);

  if (error) return { error: true };

  // Summary (+ its AI flag) ride a separate best-effort write: profiles.summary
  // (0044) and summary_ai_generated (0046) are late columns, so a DB behind on
  // either still saves the rest. Fall back to summary-only if the flag column
  // isn't there yet; the error is ignored rather than failing the whole résumé.
  const sumUpdate = await supabase
    .from("profiles")
    .update({
      summary: clean(draft.summary),
      summary_ai_generated: draft.summaryAiGenerated === true,
    })
    .eq("id", user.id);
  if (sumUpdate.error) {
    await supabase
      .from("profiles")
      .update({ summary: clean(draft.summary) })
      .eq("id", user.id);
  }

  // Replace the user's education entries with the wizard's set.
  const year = (y: string) => (/^\d{4}$/.test(y) ? `${y}-01-01` : null);
  const rows = (draft.educations ?? [])
    .filter((e) => e.school.trim() !== "")
    .map((e) => ({
      profile_id: user.id,
      school: e.school.trim(),
      degree: clean(e.degree),
      field: clean(e.field),
      start_date: year(e.startYear),
      end_date: e.isCurrent ? null : year(e.endYear),
      is_current: e.isCurrent,
    }));
  const eduOk = await replaceRows(supabase, "educations", user.id, rows);

  // Replace the user's work-experience entries with the wizard's set.
  const expRows = (draft.experiences ?? [])
    .filter((e) => e.title.trim() !== "")
    .map((e) => ({
      profile_id: user.id,
      title: e.title.trim(),
      company_name: clean(e.companyName),
      start_date: year(e.startYear),
      end_date: e.isCurrent ? null : year(e.endYear),
      is_current: e.isCurrent,
      description: clean(e.description),
    }));
  const expOk = await replaceRows(supabase, "experiences", user.id, expRows);

  // Replace the user's certificates/courses with the wizard's set.
  const certRows = (draft.certificates ?? [])
    .filter((c) => c.name.trim() !== "")
    .map((c) => ({
      profile_id: user.id,
      name: c.name.trim(),
      issuer: clean(c.issuer),
      issued_date: year(c.issuedYear),
      expiry_date: year(c.expiryYear),
    }));
  const certOk = await replaceRows(
    supabase,
    "certifications",
    user.id,
    certRows,
  );

  if (!eduOk || !expOk || !certOk) return { error: true };
  return { ok: true };
}
