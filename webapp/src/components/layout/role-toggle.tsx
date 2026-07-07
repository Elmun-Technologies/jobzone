"use client";

import { useTranslations } from "next-intl";

import { Link, usePathname } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

const segment =
  "rounded-full px-3 py-1.5 text-sm font-medium transition-colors";
const active = "bg-background text-foreground shadow-sm";
const inactive = "text-muted-foreground hover:text-foreground";

/**
 * Seeker ⇄ Employer audience switch — the master mode boundary (mirrors the
 * mobile role split). `employerHref` is resolved by the server header so a
 * guest lands on the guest-first post-a-vacancy page instead of the gated
 * employer dashboard.
 */
export function RoleToggle({
  employerHref = "/employer",
}: {
  employerHref?: string;
}) {
  const t = useTranslations("nav");
  const pathname = usePathname();
  const isEmployer = pathname.startsWith("/employer");

  return (
    <div className="bg-muted inline-flex items-center rounded-full p-1">
      <Link href="/" className={cn(segment, isEmployer ? inactive : active)}>
        {t("seeker")}
      </Link>
      <Link
        href={employerHref}
        className={cn(segment, isEmployer ? active : inactive)}
      >
        {t("employer")}
      </Link>
    </div>
  );
}
