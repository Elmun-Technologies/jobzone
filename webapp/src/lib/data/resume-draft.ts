/**
 * The résumé wizard's draft shape — the one type both halves of the auth-last
 * flow share: the server reads a profile into it (`getMyResume`) and writes it
 * back (`saveResume`), while the client wizard edits it and parks it in
 * sessionStorage across a sign-in.
 */

export interface EducationEntry {
  id?: string;
  institution: string;
  degree: string;
  field: string;
  startYear: number | null;
  endYear: number | null;
}

/** One job in the seeker's work history (the `experiences` table). */
export interface ExperienceEntry {
  id?: string;
  title: string;
  companyName: string;
  description: string;
  startYear: number | null;
  startMonth: number | null;
  endYear: number | null;
  endMonth: number | null;
  current: boolean;
}

/** A certificate / course (the `certifications` table). */
export interface CertificateEntry {
  id?: string;
  name: string;
  organization: string;
  issueDate: Date | null;
}

/** The fields the /resumes/new wizard collects. */
export interface ResumeDraft {
  positions: string[];
  fullName: string;
  region: string | null;
  city: string | null;
  experienceLevel: string;
  phone: string;
  expectedSalary: string;
  currency: string;
  summary: string;
  summaryAiGenerated: boolean;
  languages: Record<string, string>;
  experiences: ExperienceEntry[];
  educations: EducationEntry[];
  certificates: CertificateEntry[];
  resumeExists?: boolean;
}

export const EMPTY_RESUME: ResumeDraft = {
  positions: [],
  fullName: "",
  region: null,
  city: null,
  experienceLevel: "",
  phone: "",
  expectedSalary: "",
  currency: "UZS",
  summary: "",
  summaryAiGenerated: false,
  languages: {},
  experiences: [],
  educations: [],
  certificates: [],
};
