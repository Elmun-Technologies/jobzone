"use client";

import { useTranslations } from "next-intl";

import { Link, usePathname } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

// Apple-style segmented control: two equal halves + a thumb that slides. Each
// label is a centred, non-wrapping cell, so uz/ru/en all render one clean line
// at (near-)identical width — no more the Uzbek "Ish qidiruvchi" wrapping to
// two lines and making the pill taller than the compact Russian one.
const cell =
  "relative z-10 whitespace-nowrap rounded-full px-3 py-1.5 text-center text-sm font-medium transition-colors";

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
    <div className="bg-muted relative grid shrink-0 grid-cols-2 items-center rounded-full p-1">
      {/* `shrink-0`: grid-cols-2 tracks are `minmax(0,1fr)`, which have no
          protected minimum — sitting in the header's flex row, this pill was
          the first thing squeezed once the `lg:` nav/locale/theme toggles pop
          into view around the 1024px breakpoint, collapsing narrower than its
          own labels and rendering "Job seeker" and "Employer" on top of each
          other. Pinning it to its content size pushes any real overflow onto
          flexible siblings (the nav links) instead of onto unreadable text. */}
      {/* The sliding thumb. Width = one half minus the container padding; it
          translates by its own width to sit under the employer cell. */}
      <span
        aria-hidden
        className={cn(
          "bg-background pointer-events-none absolute inset-y-1 left-1 w-[calc(50%-0.25rem)] rounded-full shadow-sm transition-transform duration-200 ease-out",
          isEmployer && "translate-x-full",
        )}
      />
      <Link
        href="/"
        aria-current={isEmployer ? undefined : "page"}
        className={cn(
          cell,
          isEmployer
            ? "text-muted-foreground hover:text-foreground"
            : "text-foreground",
        )}
      >
        {t("seeker")}
      </Link>
      <Link
        href={employerHref}
        aria-current={isEmployer ? "page" : undefined}
        className={cn(
          cell,
          isEmployer
            ? "text-foreground"
            : "text-muted-foreground hover:text-foreground",
        )}
      >
        {t("employer")}
      </Link>
    </div>
  );
}
