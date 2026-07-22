"use client";

import { useTranslations } from "next-intl";

import { buttonVariants } from "@/components/ui/button";
import { Link, usePathname } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

import { navModel } from "./nav-model";

const navLink =
  "text-foreground hover:text-primary text-sm font-medium transition-colors";
// Responsive overrides must come AFTER buttonVariants: tailwind-merge keeps
// the last display utility, so "hidden" before the variants' "inline-flex"
// would be silently discarded and the CTA would never leave the phone header.
const ctaCls = cn(
  buttonVariants({ variant: "primary", size: "sm" }),
  "hidden gap-1.5 sm:inline-flex",
);

/**
 * The desktop primary nav + CTA, switched by the seeker⇄employer mode (the
 * RoleToggle lives on the `/employer/*` path, so mode is path-based). The
 * nav links are xl-only; the mobile drawer (mobile-menu) covers everything
 * below that from the same navModel so the two never drift.
 *
 * xl (1280px), not lg (1024px): at lg the role toggle, this nav, and the
 * locale/theme toggles all pop into view in the same breath that Container's
 * padding jumps `sm:px-6` → `lg:px-8` — the combined content needs ~1096px
 * at 1024px of available width, so the header overflowed (and, before the
 * toggle's own shrink-0 fix, silently squashed into overlapping text
 * instead). 1280px has confirmed room to spare.
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
      <nav className="hidden items-center gap-5 xl:flex">
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
