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
 * Goes through the `get_applicant_resume` RPC (0075) — a single SECURITY
 * DEFINER call scoped to one applicant id — rather than reading
 * experiences/educations/certifications/profile_skills/applicant_profiles
 * directly. Those objects used to grant recruiters row-level access via an
 * `is_recruiter_of`/`is_job_owner` predicate (0047/0049), which is correct
 * for WHICH rows are visible but not for the query SHAPE: an unfiltered REST
 * call under that policy returned every applicant across every one of the
 * caller's jobs in one response — a bulk-scrape side channel this app never
 * used (this reader has always queried one `profile_id` at a time) but which
 * anyone with the recruiter's JWT could exploit directly. The RPC closes that
 * off by construction: it only ever answers for the one id it's given.
 *
 * This reader does NOT enforce ownership on its own; the résumé page gates the
 * route (requireEmployer + the application must belong to the owner's job).
 * The RPC re-checks `is_recruiter_of` independently, so a bug in the page
 * gate can't turn into a cross-tenant read.
 */
export async function getApplicantResume(
  applicantId: string,
): Promise<ApplicantResume> {
  if (!hasSupabase()) return EMPTY;
  try {
    const supabase = await createClient();

    const { data, error } = await supabase.rpc("get_applicant_resume", {
      p_applicant_id: applicantId,
    });
    if (error || !data) return EMPTY;
    const payload = data as Record<string, unknown>;

    const experiences: ApplicantExperience[] = (
      (payload.experiences as unknown[]) ?? []
    ).map((e) => {
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

    const educations: ApplicantEducation[] = (
      (payload.educations as unknown[]) ?? []
    ).map((e) => {
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

    const certificates: ApplicantCertificate[] = (
      (payload.certificates as unknown[]) ?? []
    ).map((c) => {
      const row = c as Record<string, unknown>;
      return {
        name: str(row.name),
        issuer: str(row.issuer),
        issuedYear: yearOf(row.issued_date),
        expiryYear: yearOf(row.expiry_date),
      };
    });

    const skills: string[] = ((payload.skills as unknown[]) ?? []).filter(
      (n): n is string => typeof n === "string" && n !== "",
    );

    const languages =
      payload.languages && typeof payload.languages === "object"
        ? (payload.languages as Record<string, string>)
        : {};
    const summary = str(payload.summary);
    const experienceLevel = str(payload.experience_level);
    const expectedSalary =
      payload.desired_pay_min != null ? String(payload.desired_pay_min) : "";

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
      summaryAiGenerated: payload.summary_ai_generated === true,
      experienceLevel,
      expectedSalary,
      currency: str(payload.desired_pay_currency) || "UZS",
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
