"use client";

import { FilePlus2, Users } from "lucide-react";
import { useTranslations } from "next-intl";

import { buttonVariants } from "@/components/ui/button";
import { Link, usePathname } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

const navLink =
  "text-foreground hover:text-primary text-sm font-medium transition-colors";
const ctaCls =
  "hidden gap-1.5 sm:inline-flex " +
  buttonVariants({ variant: "primary", size: "sm" });

/**
 * The primary nav + CTA, switched by the seeker⇄employer mode (the RoleToggle
 * lives on the `/employer/*` path, so mode is path-based). Employer mode
 * replaces the whole set — seeker links + "create résumé" become employer
 * links + a candidates/post-a-vacancy CTA. Client so it can read the path.
 */
export function HeaderNav({
  signedIn,
  isEmployerAccount,
}: {
  signedIn: boolean;
  isEmployerAccount: boolean;
}) {
  const t = useTranslations("nav");
  const pathname = usePathname();
  const employerMode = pathname.startsWith("/employer");

  if (employerMode) {
    // Signed-in employers review candidates; everyone else (guest / seeker)
    // is sent to post a vacancy first — no vacancies, no résumés to review.
    const cta =
      signedIn && isEmployerAccount
        ? { href: "/employer", label: t("candidates"), Icon: Users }
        : {
            href: "/employer/jobs/new",
            label: t("postVacancy"),
            Icon: FilePlus2,
          };
    return (
      <>
        <nav className="hidden items-center gap-5 lg:flex">
          <Link href="/employer" className={navLink}>
            {t("dashboard")}
          </Link>
          <Link href="/employer/jobs" className={navLink}>
            {t("vacancies")}
          </Link>
          <Link href="/employer/company/edit" className={navLink}>
            {t("company")}
          </Link>
        </nav>
        <Link href={cta.href} className={cn(ctaCls)}>
          <cta.Icon className="size-4" />
          {cta.label}
        </Link>
      </>
    );
  }

  return (
    <>
      <nav className="hidden items-center gap-5 lg:flex">
        <Link href="/" className={navLink}>
          {t("home")}
        </Link>
        <Link href="/jobs" className={navLink}>
          {t("jobs")}
        </Link>
        <Link href="/companies" className={navLink}>
          {t("companies")}
        </Link>
        <Link href="/about" className={navLink}>
          {t("about")}
        </Link>
        <Link href="/account/bookmarks" className={navLink}>
          {t("saved")}
        </Link>
      </nav>
      <Link href="/resumes/new" className={cn(ctaCls)}>
        <FilePlus2 className="size-4" />
        {t("createResume")}
      </Link>
    </>
  );
}
