"use server";

import { createClient } from "@/lib/supabase/server";
import type {
  CertificateEntry,
  EducationEntry,
  ExperienceEntry,
  ResumeDraft,
} from "@/lib/data/resume";

export interface SaveResumeResult {
  ok?: boolean;
  signedOut?: boolean;
  error?: boolean;
  /** The signed-in account already has a résumé, but this draft never saw
   * it (a guest-built draft, see ResumeDraft.resumeExists) — refused rather
   * than silently overwritten. The caller should discard the draft and
   * reload the real one. */
  conflict?: boolean;
}

const clean = (v: string) => {
  const t = v.trim();
  return t === "" ? null : t;
};

/**
 * Reconciles a profile's rows in a résumé sub-table against [rows] instead of
 * blindly replacing all of them.
 *
 * Each row with an `id` updates that row with exactly the columns [toRow]
 * returns — an `upsert` only ever touches the columns present in the payload,
 * so a column this form doesn't know about (mobile-only fields like
 * `experiences.location`, `educations.grade`/`description`,
 * `certifications.credential_id`/`credential_url`) is left exactly as it
 * was. A row with no `id` is a fresh insert (`id` defaults to
 * `gen_random_uuid()`). Any EXISTING row whose id isn't present in [rows] was
 * removed by the seeker in the wizard and is deleted.
 *
 * This used to be delete-everything-then-insert-only-what-the-wizard-knows,
 * which silently destroyed every mobile-only column on every save.
 */
async function reconcileRows<T extends { id?: string }>(
  supabase: Awaited<ReturnType<typeof createClient>>,
  table: string,
  profileId: string,
  rows: T[],
  toRow: (row: T) => Record<string, unknown>,
): Promise<boolean> {
  const { data: existingRows, error: selErr } = await supabase
    .from(table)
    .select("id")
    .eq("profile_id", profileId);
  if (selErr) return false;

  const keepIds = new Set(
    rows.map((r) => r.id).filter((id): id is string => Boolean(id)),
  );
  const toDelete = (existingRows ?? [])
    .map((r) => String((r as { id: unknown }).id))
    .filter((id) => !keepIds.has(id));
  if (toDelete.length) {
    const del = await supabase.from(table).delete().in("id", toDelete);
    if (del.error) return false;
  }

  if (rows.length === 0) return true;
  const payload = rows.map((r) => ({
    ...toRow(r),
    ...(r.id ? { id: r.id } : {}),
  }));
  const ups = await supabase.from(table).upsert(payload, { onConflict: "id" });
  return !ups.error;
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

  // This draft never saw the account's real data (built from EMPTY_RESUME
  // while signed out — e.g. quick-apply's guest path, or a session that
  // expired mid-wizard). If the NOW-authenticated account already has a
  // résumé, saving this draft as-is would delete/overwrite it with rows and
  // ids it knows nothing about. Refuse instead of guessing.
  if (!draft.resumeExists) {
    const [edu, exp, cert] = await Promise.all([
      supabase
        .from("educations")
        .select("id")
        .eq("profile_id", user.id)
        .limit(1),
      supabase
        .from("experiences")
        .select("id")
        .eq("profile_id", user.id)
        .limit(1),
      supabase
        .from("certifications")
        .select("id")
        .eq("profile_id", user.id)
        .limit(1),
    ]);
    const hasExistingRows =
      (edu.data?.length ?? 0) > 0 ||
      (exp.data?.length ?? 0) > 0 ||
      (cert.data?.length ?? 0) > 0;
    if (hasExistingRows) return { conflict: true };
  }

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

  const year = (y: string) => (/^\d{4}$/.test(y) ? `${y}-01-01` : null);

  const eduRows = (draft.educations ?? []).filter(
    (e) => e.school.trim() !== "",
  );
  const eduOk = await reconcileRows<EducationEntry>(
    supabase,
    "educations",
    user.id,
    eduRows,
    (e) => ({
      profile_id: user.id,
      school: e.school.trim(),
      degree: clean(e.degree),
      field: clean(e.field),
      start_date: year(e.startYear),
      end_date: e.isCurrent ? null : year(e.endYear),
      is_current: e.isCurrent,
    }),
  );

  const expRows = (draft.experiences ?? []).filter(
    (e) => e.title.trim() !== "",
  );
  const expOk = await reconcileRows<ExperienceEntry>(
    supabase,
    "experiences",
    user.id,
    expRows,
    (e) => ({
      profile_id: user.id,
      title: e.title.trim(),
      company_name: clean(e.companyName),
      start_date: year(e.startYear),
      end_date: e.isCurrent ? null : year(e.endYear),
      is_current: e.isCurrent,
      description: clean(e.description),
    }),
  );

  const certRows = (draft.certificates ?? []).filter(
    (c) => c.name.trim() !== "",
  );
  const certOk = await reconcileRows<CertificateEntry>(
    supabase,
    "certifications",
    user.id,
    certRows,
    (c) => ({
      profile_id: user.id,
      name: c.name.trim(),
      issuer: clean(c.issuer),
      issued_date: year(c.issuedYear),
      expiry_date: year(c.expiryYear),
    }),
  );

  if (!eduOk || !expOk || !certOk) return { error: true };
  return { ok: true };
}
