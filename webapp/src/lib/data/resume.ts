import "server-only";

import { createClient } from "@/lib/supabase/server";

import { hasSupabase } from "./supabase-env";

export interface EducationEntry {
  school: string;
  degree: string;
  field: string;
  startYear: string;
  endYear: string;
  isCurrent: boolean;
}

/** The fields the /resumes/new wizard collects. */
export interface ResumeDraft {
  position: string; // headline
  fullName: string;
  city: string;
  gender: string; // "" | "male" | "female"
  birthDate: string; // "YYYY-MM-DD" | ""
  maritalStatus: string; // "" | "single" | "married" | "divorced"
  experienceLevel: string; // "" | none | under_1 | 1_3 | 3_5 | 5_plus
  expectedSalary: string; // numeric string | ""
  currency: string; // "UZS" | "USD"
  phone: string;
  email: string;
  /** language code -> level ("none"|"a1_a2"|"b1_b2"|"c1_c2"|"native"). */
  languages: Record<string, string>;
  educations: EducationEntry[];
}

export const EMPTY_RESUME: ResumeDraft = {
  position: "",
  fullName: "",
  city: "",
  gender: "",
  birthDate: "",
  maritalStatus: "",
  experienceLevel: "",
  expectedSalary: "",
  currency: "UZS",
  phone: "",
  email: "",
  languages: {},
  educations: [],
};

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
      .select("school, degree, field, start_date, end_date, is_current")
      .eq("profile_id", user.id)
      .order("end_date", { ascending: false, nullsFirst: false });
    const educations: EducationEntry[] = (eduRows ?? []).map((e) => {
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

    const langs =
      r.languages && typeof r.languages === "object"
        ? (r.languages as Record<string, string>)
        : {};

    return {
      position: str(r.headline),
      fullName: str(r.full_name),
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
      languages: langs,
      educations,
    };
  } catch {
    return EMPTY_RESUME;
  }
}
