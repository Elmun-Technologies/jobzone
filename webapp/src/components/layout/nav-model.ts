import { FilePlus2, Users, type LucideIcon } from "lucide-react";

export interface NavItem {
  href: string;
  labelKey: string;
}
export interface NavModel {
  employerMode: boolean;
  links: NavItem[];
  cta: { href: string; labelKey: string; Icon: LucideIcon };
}

/**
 * The mode-aware header nav + CTA (seeker vs employer, from the path). Shared
 * by the desktop nav (header-nav) and the mobile drawer (mobile-menu) so the
 * two never drift. Labels are i18n keys under the "nav" namespace.
 */
export function navModel(
  pathname: string,
  signedIn: boolean,
  isEmployerAccount: boolean,
): NavModel {
  if (pathname.startsWith("/employer")) {
    // Signed-in employers review candidates; everyone else (guest / seeker) is
    // sent to post a vacancy first — no vacancies, no résumés to review.
    return {
      employerMode: true,
      links: [
        { href: "/employer", labelKey: "dashboard" },
        { href: "/employer/jobs", labelKey: "vacancies" },
        { href: "/employer/company/edit", labelKey: "company" },
      ],
      cta:
        signedIn && isEmployerAccount
          ? { href: "/employer", labelKey: "candidates", Icon: Users }
          : {
              href: "/employer/jobs/new",
              labelKey: "postVacancy",
              Icon: FilePlus2,
            },
    };
  }
  return {
    employerMode: false,
    links: [
      { href: "/", labelKey: "home" },
      { href: "/jobs", labelKey: "jobs" },
      { href: "/companies", labelKey: "companies" },
      { href: "/about", labelKey: "about" },
      { href: "/account/bookmarks", labelKey: "saved" },
    ],
    cta: { href: "/resumes/new", labelKey: "createResume", Icon: FilePlus2 },
  };
}
