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

export {
  EMPTY_RESUME,
  type CertificateEntry,
  type EducationEntry,
  type ExperienceEntry,
  type ResumeDraft,
} from "./resume-draft";

function yearOf(v: unknown): number | null {
  if (typeof v !== "string") return null;
  const d = new Date(v);
  return isNaN(d.getTime()) ? null : d.getFullYear();
}

function monthOf(v: unknown): number | null {
  if (typeof v !== "string") return null;
  const d = new Date(v);
  return isNaN(d.getTime()) ? null : d.getMonth() + 1;
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
    
    const { data: profile } = await supabase
      .from("profiles")
      .select("full_name, phone, languages, summary, summary_ai_generated, desired_positions, desired_region, desired_district, city, experience_level")
      .eq("id", user.id)
      .maybeSingle();
    
    const r = (profile ?? {}) as Record<string, unknown>;

    const { data: eduRows } = await supabase
      .from("educations")
      .select("id, school, degree, field, start_date, end_date, is_current")
      .eq("profile_id", user.id)
      .order("end_date", { ascending: false, nullsFirst: false });
    
    const educations: EducationEntry[] = (eduRows ?? []).map((e) => {
      const row = e as Record<string, unknown>;
      return {
        id: str(row.id) || undefined,
        institution: str(row.school),
        degree: str(row.degree),
        field: str(row.field),
        startYear: yearOf(row.start_date),
        endYear: yearOf(row.end_date),
      };
    });

    const { data: expRows } = await supabase
      .from("experiences")
      .select("id, title, company_name, start_date, end_date, is_current, description")
      .eq("profile_id", user.id)
      .order("end_date", { ascending: false, nullsFirst: false });
    
    const experiences: ExperienceEntry[] = (expRows ?? []).map((e) => {
      const row = e as Record<string, unknown>;
      return {
        id: str(row.id) || undefined,
        title: str(row.title),
        companyName: str(row.company_name),
        description: str(row.description),
        startYear: yearOf(row.start_date),
        startMonth: monthOf(row.start_date),
        endYear: yearOf(row.end_date),
        endMonth: monthOf(row.end_date),
        current: row.is_current === true,
      };
    });

    const { data: certRows } = await supabase
      .from("certifications")
      .select("id, name, issuer, issued_date")
      .eq("profile_id", user.id)
      .order("issued_date", { ascending: false, nullsFirst: false });
    
    const certificates: CertificateEntry[] = (certRows ?? []).map((c) => {
      const row = c as Record<string, unknown>;
      return {
        id: str(row.id) || undefined,
        name: str(row.name),
        organization: str(row.issuer),
        issueDate: row.issued_date ? new Date(row.issued_date as string) : null,
      };
    });

    return {
      positions: Array.isArray(r.desired_positions) ? (r.desired_positions as string[]) : [],
      fullName: str(r.full_name),
      region: str(r.desired_region) || null,
      city: str(r.desired_district) || str(r.desired_region) || str(r.city) || null,
      experienceLevel: str(r.experience_level),
      phone: str(r.phone),
      expectedSalary: r.desired_pay_min != null ? String(r.desired_pay_min) : "",
      currency: str(r.desired_pay_currency) || "UZS",
      summary: str(r.summary),
      summaryAiGenerated: r.summary_ai_generated === true,
      languages: (r.languages as Record<string, string>) ?? {},
      experiences,
      educations,
      certificates,
      resumeExists: true,
    };
  } catch (e) {
    console.error("getMyResume error:", e);
    return EMPTY_RESUME;
  }
}
