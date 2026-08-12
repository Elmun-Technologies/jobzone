import "server-only";

import { createClient } from "@/lib/supabase/server";

import {
  EMPTY_RESUME,
  type CertificateEntry,
  type EducationEntry,
  type ExperienceEntry,
  type ResumeDraft,
} from "./resume-draft";
import { hasSupabase } from "./supabase-env";

// Re-exported so every existing `@/lib/data/resume` import keeps working; the
// shapes themselves live in the client-safe module next door.
export {
  EMPTY_RESUME,
  type CertificateEntry,
  type EducationEntry,
  type ExperienceEntry,
  type ResumeDraft,
} from "./resume-draft";

function yearOf(v: unknown): string {
  return typeof v === "string" && v.length >= 4 ? v.slice(0, 4) : "";
}

const str = (v: unknown) => (typeof v === "string" ? v : "");

/** Pre-fills the wizard from the signed-in user's existing profile. */
export async function getMyResume(): Promise<ResumeDraft> {
  if (!hasSupabase()) return EMPTY_RESUME;
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return EMPTY_RESUME;
    const { data } = await supabase
      .from("profiles")
      .select(
        "full_name, headline, city, gender, birth_date, marital_status, experience_level, desired_pay_min, desired_pay_currency, phone, email, languages",
      )
      .eq("id", user.id)
      .maybeSingle();
    const r = (data ?? {}) as Record<string, unknown>;

    const { data: eduRows } = await supabase
      .from("educations")
      .select("id, school, degree, field, start_date, end_date, is_current")
      .eq("profile_id", user.id)
      .order("end_date", { ascending: false, nullsFirst: false });
    const educations: EducationEntry[] = (eduRows ?? []).map((e) => {
      const row = e as Record<string, unknown>;
      return {
        id: str(row.id) || undefined,
        school: str(row.school),
        degree: str(row.degree),
        field: str(row.field),
        startYear: yearOf(row.start_date),
        endYear: yearOf(row.end_date),
        isCurrent: row.is_current === true,
      };
    });

    const { data: expRows } = await supabase
      .from("experiences")
      .select(
        "id, title, company_name, start_date, end_date, is_current, description",
      )
      .eq("profile_id", user.id)
      .order("end_date", { ascending: false, nullsFirst: false });
    const experiences: ExperienceEntry[] = (expRows ?? []).map((e) => {
      const row = e as Record<string, unknown>;
      return {
        id: str(row.id) || undefined,
        title: str(row.title),
        companyName: str(row.company_name),
        startYear: yearOf(row.start_date),
        endYear: yearOf(row.end_date),
        isCurrent: row.is_current === true,
        description: str(row.description),
      };
    });

    const { data: certRows } = await supabase
      .from("certifications")
      .select("id, name, issuer, issued_date, expiry_date")
      .eq("profile_id", user.id)
      .order("issued_date", { ascending: false, nullsFirst: false });
    const certificates: CertificateEntry[] = (certRows ?? []).map((c) => {
      const row = c as Record<string, unknown>;
      return {
        id: str(row.id) || undefined,
        name: str(row.name),
        issuer: str(row.issuer),
        issuedYear: yearOf(row.issued_date),
        expiryYear: yearOf(row.expiry_date),
      };
    });

    const langs =
      r.languages && typeof r.languages === "object"
        ? (r.languages as Record<string, string>)
        : {};

    // summary (0044) + summary_ai_generated (0046) are late columns; read them
    // separately — and fall back to just summary if the flag column isn't there
    // yet — so a DB behind on either migration still returns the rest.
    let summary = "";
    let summaryAiGenerated = false;
    let sumRes = await supabase
      .from("profiles")
      .select("summary, summary_ai_generated")
      .eq("id", user.id)
      .maybeSingle();
    if (sumRes.error) {
      sumRes = await supabase
        .from("profiles")
        .select("summary")
        .eq("id", user.id)
        .maybeSingle();
    }
    const sr = (sumRes.data ?? {}) as {
      summary?: unknown;
      summary_ai_generated?: unknown;
    };
    if (typeof sr.summary === "string") summary = sr.summary;
    if (sr.summary_ai_generated === true) summaryAiGenerated = true;

    // desired_positions / desired_region / desired_district are 0082 columns —
    // read separately, same as summary above, so a DB that hasn't taken the
    // migration yet still returns a working résumé instead of erroring out.
    let positions: string[] = [];
    let region = "";
    let district = "";
    const locRes = await supabase
      .from("profiles")
      .select("desired_positions, desired_region, desired_district")
      .eq("id", user.id)
      .maybeSingle();
    if (!locRes.error) {
      const lr = (locRes.data ?? {}) as Record<string, unknown>;
      if (Array.isArray(lr.desired_positions)) {
        positions = lr.desired_positions.filter(
          (p): p is string => typeof p === "string" && p.trim() !== "",
        );
      }
      region = str(lr.desired_region);
      district = str(lr.desired_district);
    }
    // Pre-0082 résumés (and DBs behind on it) only have the headline.
    if (positions.length === 0 && str(r.headline).trim() !== "") {
      positions = [str(r.headline)];
    }

    return {
      positions,
      fullName: str(r.full_name),
      region,
      district,
      city: str(r.city),
      gender: str(r.gender),
      birthDate: str(r.birth_date),
      maritalStatus: str(r.marital_status),
      experienceLevel: str(r.experience_level),
      expectedSalary:
        r.desired_pay_min != null ? String(r.desired_pay_min) : "",
      currency: str(r.desired_pay_currency) || "UZS",
      phone: str(r.phone),
      email: str(r.email) || (user.email ?? ""),
      summary,
      summaryAiGenerated,
      languages: langs,
      experiences,
      educations,
      certificates,
      resumeExists: true,
    };
  } catch {
    return EMPTY_RESUME;
  }
}
