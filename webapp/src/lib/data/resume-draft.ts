/**
 * The résumé wizard's draft shape — the one type both halves of the auth-last
 * flow share: the server reads a profile into it (`getMyResume`) and writes it
 * back (`saveResume`), while the client wizard edits it and parks it in
 * sessionStorage across a sign-in.
 *
 * Split out of `data/resume.ts` because that file is `server-only`: the wizard
 * is a client component and needs `EMPTY_RESUME` at runtime, not just the
 * types.
 */

export interface EducationEntry {
  school: string;
  degree: string;
  field: string;
  startYear: string;
  endYear: string;
  isCurrent: boolean;
}

/** One job in the seeker's work history (the `experiences` table). */
export interface ExperienceEntry {
  title: string; // position held
  companyName: string;
  startYear: string;
  endYear: string;
  isCurrent: boolean;
  description: string;
}

/** A certificate / course (the `certifications` table). */
export interface CertificateEntry {
  name: string;
  issuer: string;
  issuedYear: string;
  /** "" = no expiry (lifetime). */
  expiryYear: string;
}

/** The fields the /resumes/new wizard collects. */
export interface ResumeDraft {
  /** Up to three desired job titles (profiles.desired_positions, 0078). The
   * first one is also written to `headline`, which stays the single title every
   * card, chat header and applicant row renders. */
  positions: string[];
  fullName: string;
  /** Canonical viloyat from UZ_DISTRICTS (profiles.desired_region, 0078). */
  region: string;
  /** Canonical tuman inside `region` (profiles.desired_district, 0078). */
  district: string;
  /** Derived at save time as district || region — kept because `profiles.city`
   * is what the cards show and what pre-0078 rows match on. */
  city: string;
  gender: string; // "" | "male" | "female"
  birthDate: string; // "YYYY-MM-DD" | ""
  maritalStatus: string; // "" | "single" | "married" | "divorced"
  experienceLevel: string; // "" | none | under_1 | 1_3 | 3_5 | 5_plus
  expectedSalary: string; // numeric string | ""
  currency: string; // "UZS" | "USD"
  phone: string;
  email: string;
  /** Free-text professional summary ("About me"), AI-assisted (profiles.summary,
   * 0044). Read/written separately so a DB behind on that migration still works. */
  summary: string;
  /** True while the summary is the untouched AI draft (profiles.summary_ai_generated,
   * 0046) — set by "Write with AI", cleared when the seeker edits the text. */
  summaryAiGenerated: boolean;
  /** language code -> level ("none"|"a1_a2"|"b1_b2"|"c1_c2"|"native"). */
  languages: Record<string, string>;
  experiences: ExperienceEntry[];
  educations: EducationEntry[];
  certificates: CertificateEntry[];
}

export const EMPTY_RESUME: ResumeDraft = {
  positions: [],
  fullName: "",
  region: "",
  district: "",
  city: "",
  gender: "",
  birthDate: "",
  maritalStatus: "",
  experienceLevel: "",
  expectedSalary: "",
  currency: "UZS",
  phone: "",
  email: "",
  summary: "",
  summaryAiGenerated: false,
  languages: {},
  experiences: [],
  educations: [],
  certificates: [],
};
