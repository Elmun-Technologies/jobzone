import "server-only";

import { createClient } from "@/lib/supabase/server";

import {
  type ApplicantCertificate,
  type ApplicantEducation,
  type ApplicantExperience,
  type ApplicantResume,
} from "./types";

const EMPTY: ApplicantResume = {
  summary: "",
  summaryAiGenerated: false,
  languages: {},
  experienceLevel: "",
  desiredPayMin: null,
  desiredPayCurrency: "UZS",
  experiences: [],
  educations: [],
  certificates: [],
  skills: [],
};

/**
 * Reads an applicant's full résumé (CV) for the employer view.
 *
 * Secure: uses a SECURITY DEFINER RPC (`get_applicant_resume`) that re-checks
 * recruiter authorization itself. This closes a bulk-scraping side channel where
 * a recruiter could otherwise issue unfiltered REST calls to the base tables
 * and harvest every applicant's full work history in one go (0075).
 */
export async function getApplicantResume(
  applicantId: string,
): Promise<ApplicantResume> {
  try {
    const supabase = await createClient();

    const { data, error } = await supabase.rpc("get_applicant_resume", {
      p_applicant_id: applicantId,
    });
    if (error || !data) return EMPTY;
    const payload = data as Record<string, unknown>;

    const str = (v: unknown) => (typeof v === "string" ? v : "");
    const yearOf = (v: unknown) => {
      if (typeof v !== "string") return null;
      const d = new Date(v);
      return isNaN(d.getTime()) ? null : d.getFullYear();
    };

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

    // Sign the attached documents in one batch. Best-effort like everything
    // else here: a DB behind on 0077 has no file_path column, and a storage
    // hiccup costs the link, not the section.
    const certRows = (payload.certificates as unknown[]) ?? [];
    const certUrls = await Promise.all(
      certRows.map(async (c) => {
        const row = c as Record<string, unknown>;
        const path = str(row.file_path);
        if (!path) return "";
        try {
          const { data } = await supabase.storage
            .from("certificates")
            .createSignedUrl(path, 60 * 10);
          return data?.signedUrl ?? "";
        } catch {
          return "";
        }
      }),
    );

    const certificates: ApplicantCertificate[] = certRows.map((c, i) => {
      const row = c as Record<string, unknown>;
      return {
        name: str(row.name),
        issuer: str(row.issuer),
        issuedYear: yearOf(row.issued_date),
        expiryYear: yearOf(row.expiry_date),
        fileUrl: certUrls[i] ?? "",
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

    return {
      summary,
      summaryAiGenerated: payload.summary_ai_generated === true,
      languages,
      experienceLevel,
      desiredPayMin: (payload.desired_pay_min as number) || null,
      desiredPayCurrency: str(payload.desired_pay_currency) || "UZS",
      experiences,
      educations,
      certificates,
      skills,
    };
  } catch (e) {
    console.error("Failed to read applicant resume:", e);
    return EMPTY;
  }
}
