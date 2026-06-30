"use client";

import { useTranslations } from "next-intl";

import { Link, usePathname } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

const segment =
  "rounded-full px-3 py-1.5 text-sm font-medium transition-colors";
const active = "bg-background text-foreground shadow-sm";
const inactive = "text-muted-foreground hover:text-foreground";

/** Seeker ⇄ Employer audience switch (mirrors the mobile role split). */
export function RoleToggle() {
  const t = useTranslations("nav");
  const pathname = usePathname();
  const isEmployer = pathname.startsWith("/employer");

  return (
    <div className="bg-muted inline-flex items-center rounded-full p-1">
      <Link href="/" className={cn(segment, isEmployer ? inactive : active)}>
        {t("seeker")}
      </Link>
      <Link
        href="/employer"
        className={cn(segment, isEmployer ? active : inactive)}
      >
        {t("employer")}
      </Link>
    </div>
  );
}
