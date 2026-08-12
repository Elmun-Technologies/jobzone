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
  conflict?: boolean;
}

const clean = (v: string | null | undefined) => {
  if (!v) return null;
  const t = v.trim();
  return t === "" ? null : t;
};

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

export async function saveResume(
  draft: ResumeDraft,
): Promise<SaveResumeResult> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { signedOut: true };

  // Conflict check: if the account already has a resume but the draft is "new"
  if (!draft.resumeExists) {
    const { count } = await supabase
      .from("experiences")
      .select("*", { count: "exact", head: true })
      .eq("profile_id", user.id);
    if ((count ?? 0) > 0) return { conflict: true };
  }

  const positions = Array.from(
    new Set((draft.positions ?? []).map((p) => p.trim()).filter(Boolean)),
  ).slice(0, 3);
  const pay = Number(draft.expectedSalary);

  const { error } = await supabase
    .from("profiles")
    .update({
      full_name: clean(draft.fullName),
      headline: positions[0] ?? null,
      experience_level: clean(draft.experienceLevel),
      phone: clean(draft.phone),
      desired_pay_min: Number.isFinite(pay) && pay > 0 ? pay : null,
      desired_pay_currency: draft.currency === "USD" ? "USD" : "UZS",
      languages: draft.languages ?? {},
      summary: clean(draft.summary),
      summary_ai_generated: draft.summaryAiGenerated === true,
      desired_positions: positions.length > 0 ? positions : null,
      desired_region: clean(draft.region),
      desired_district: clean(draft.city),
      city: clean(draft.city) || clean(draft.region),
      onboarding_complete: true,
    })
    .eq("id", user.id);

  if (error) return { error: true };

  const toDate = (y: number | null, m: number | null = 1) => 
    y ? `${y}-${String(m ?? 1).padStart(2, "0")}-01` : null;

  const eduOk = await reconcileRows<EducationEntry>(
    supabase,
    "educations",
    user.id,
    draft.educations.filter(e => e.institution.trim() !== ""),
    (e) => ({
      profile_id: user.id,
      school: e.institution.trim(),
      degree: clean(e.degree),
      field: clean(e.field),
      start_date: toDate(e.startYear),
      end_date: toDate(e.endYear),
    }),
  );

  const expOk = await reconcileRows<ExperienceEntry>(
    supabase,
    "experiences",
    user.id,
    draft.experiences.filter(e => e.title.trim() !== ""),
    (e) => ({
      profile_id: user.id,
      title: e.title.trim(),
      company_name: clean(e.companyName),
      description: clean(e.description),
      start_date: toDate(e.startYear, e.startMonth),
      end_date: e.current ? null : toDate(e.endYear, e.endMonth),
      is_current: e.current,
    }),
  );

  const certOk = await reconcileRows<CertificateEntry>(
    supabase,
    "certifications",
    user.id,
    draft.certificates.filter(c => c.name.trim() !== ""),
    (c) => ({
      profile_id: user.id,
      name: c.name.trim(),
      issuer: clean(c.organization),
      issued_date: c.issueDate ? c.issueDate.toISOString() : null,
    }),
  );

  if (!eduOk || !expOk || !certOk) return { error: true };
  return { ok: true };
}
