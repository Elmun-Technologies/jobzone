"use client";

import { useTranslations } from "next-intl";

import { buttonVariants } from "@/components/ui/button";
import { Link, usePathname } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

import { navModel } from "./nav-model";

const navLink =
  "text-foreground hover:text-primary text-sm font-medium transition-colors";
const ctaCls =
  "hidden gap-1.5 sm:inline-flex " +
  buttonVariants({ variant: "primary", size: "sm" });

/**
 * The desktop primary nav + CTA, switched by the seeker⇄employer mode (the
 * RoleToggle lives on the `/employer/*` path, so mode is path-based). The
 * nav links are lg-only; the mobile drawer (mobile-menu) covers smaller
 * screens from the same navModel so the two never drift.
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
  const { links, cta } = navModel(pathname, signedIn, isEmployerAccount);

  return (
    <>
      <nav className="hidden items-center gap-5 lg:flex">
        {links.map((l) => (
          <Link key={l.href} href={l.href} className={navLink}>
            {t(l.labelKey)}
          </Link>
        ))}
      </nav>
      <Link href={cta.href} className={cn(ctaCls)}>
        <cta.Icon className="size-4" />
        {t(cta.labelKey)}
      </Link>
    </>
  );
}
