import "server-only";

import { createClient } from "@/lib/supabase/server";

import { hasSupabase } from "./supabase-env";

export interface ApplicantExperience {
  title: string;
  companyName: string;
  startYear: string;
  endYear: string;
  isCurrent: boolean;
  description: string;
}

export interface ApplicantEducation {
  school: string;
  degree: string;
  field: string;
  startYear: string;
  endYear: string;
  isCurrent: boolean;
}

export interface ApplicantCertificate {
  name: string;
  issuer: string;
  issuedYear: string;
  expiryYear: string;
}

export interface ApplicantResume {
  summary: string;
  /** True when the summary is an untouched AI draft (surfaced as a badge). */
  summaryAiGenerated: boolean;
  experienceLevel: string; // "" | none | under_1 | 1_3 | 3_5 | 5_plus
  expectedSalary: string; // numeric string | ""
  currency: string; // "UZS" | "USD"
  /** language code / name -> level ("a1_a2"|"b1_b2"|"c1_c2"|"native"|...). */
  languages: Record<string, string>;
  experiences: ApplicantExperience[];
  educations: ApplicantEducation[];
  certificates: ApplicantCertificate[];
  skills: string[];
  /** True once any section has content (else the page shows an empty note). */
  hasAny: boolean;
}

function yearOf(v: unknown): string {
  return typeof v === "string" && v.length >= 4 ? v.slice(0, 4) : "";
}
const str = (v: unknown) => (typeof v === "string" ? v : "");

const EMPTY: ApplicantResume = {
  summary: "",
  summaryAiGenerated: false,
  experienceLevel: "",
  expectedSalary: "",
  currency: "UZS",
  languages: {},
  experiences: [],
  educations: [],
  certificates: [],
  skills: [],
  hasAny: false,
};

/**
 * The full résumé of a candidate who applied to one of the caller's jobs.
 *
 * The sub-tables (experiences/educations/certifications/profile_skills) are
 * `selectable by authenticated` (0001) and read directly; the profile-level
 * fields (summary + AI flag, languages, experience level, expected pay) live on
 * the owner-only `profiles` table (0027) and come through the
 * `is_job_owner`-gated `applicant_profiles` view (0047). Everything is additive
 * and best-effort — a DB behind on 0047 still returns the sub-table sections.
 *
 * This reader does NOT enforce ownership on its own; the résumé page gates the
 * route (requireEmployer + the application must belong to the owner's job).
 */
export async function getApplicantResume(
  applicantId: string,
): Promise<ApplicantResume> {
  if (!hasSupabase()) return EMPTY;
  try {
    const supabase = await createClient();

    const [expR, eduR, certR, skillR, profR] = await Promise.all([
      supabase
        .from("experiences")
        .select(
          "title, company_name, start_date, end_date, is_current, description",
        )
        .eq("profile_id", applicantId)
        // nullsFirst: an ongoing role has end_date=null and is the most recent —
        // it must sort to the TOP, not the bottom.
        .order("end_date", { ascending: false, nullsFirst: true }),
      supabase
        .from("educations")
        .select("school, degree, field, start_date, end_date, is_current")
        .eq("profile_id", applicantId)
        .order("end_date", { ascending: false, nullsFirst: true }),
      supabase
        .from("certifications")
        .select("name, issuer, issued_date, expiry_date")
        .eq("profile_id", applicantId)
        .order("issued_date", { ascending: false, nullsFirst: false }),
      supabase
        .from("profile_skills")
        .select("skills(name)")
        .eq("profile_id", applicantId),
      supabase
        .from("applicant_profiles")
        .select(
          "summary, summary_ai_generated, languages, experience_level, desired_pay_min, desired_pay_currency",
        )
        .eq("applicant_id", applicantId)
        .maybeSingle(),
    ]);

    const experiences: ApplicantExperience[] = (expR.data ?? []).map((e) => {
      const row = e as Record<string, unknown>;
      return {
        title: str(row.title),
        companyName: str(row.company_name),
        startYear: yearOf(row.start_date),
        endYear: yearOf(row.end_date),
        isCurrent: row.is_current === true,
        description: str(row.description),
      };
    });

    const educations: ApplicantEducation[] = (eduR.data ?? []).map((e) => {
      const row = e as Record<string, unknown>;
      return {
        school: str(row.school),
        degree: str(row.degree),
        field: str(row.field),
        startYear: yearOf(row.start_date),
        endYear: yearOf(row.end_date),
        isCurrent: row.is_current === true,
      };
    });

    const certificates: ApplicantCertificate[] = (certR.data ?? []).map((c) => {
      const row = c as Record<string, unknown>;
      return {
        name: str(row.name),
        issuer: str(row.issuer),
        issuedYear: yearOf(row.issued_date),
        expiryYear: yearOf(row.expiry_date),
      };
    });

    const skills: string[] = (skillR.data ?? [])
      .map((s) => {
        const sk = (s as Record<string, unknown>).skills as Record<
          string,
          unknown
        > | null;
        return sk && typeof sk.name === "string" ? sk.name : "";
      })
      .filter((n): n is string => n !== "");

    const pr = (profR.data ?? {}) as Record<string, unknown>;
    const languages =
      pr.languages && typeof pr.languages === "object"
        ? (pr.languages as Record<string, string>)
        : {};
    const summary = str(pr.summary);
    const experienceLevel = str(pr.experience_level);
    const expectedSalary =
      pr.desired_pay_min != null ? String(pr.desired_pay_min) : "";

    const hasAny =
      summary !== "" ||
      experiences.length > 0 ||
      educations.length > 0 ||
      certificates.length > 0 ||
      skills.length > 0 ||
      Object.keys(languages).length > 0 ||
      experienceLevel !== "" ||
      expectedSalary !== "";

    return {
      summary,
      summaryAiGenerated: pr.summary_ai_generated === true,
      experienceLevel,
      expectedSalary,
      currency: str(pr.desired_pay_currency) || "UZS",
      languages,
      experiences,
      educations,
      certificates,
      skills,
      hasAny,
    };
  } catch (e) {
    console.error("getApplicantResume failed", e);
    return EMPTY;
  }
}
