import { List } from "lucide-react";
import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { JobsMap } from "@/components/map/jobs-map";
import { buttonVariants } from "@/components/ui/button";
import { getCompanyRatings } from "@/lib/data/companies";
import { getOpenJobs } from "@/lib/data/jobs";
import { Link } from "@/i18n/navigation";
import { localeAlternates } from "@/lib/seo";
import { cn } from "@/lib/utils";

// The map reads the live open-job feed; a static prerender would freeze the pins
// at build time — new postings must show immediately (invariant #3) — and bake a
// logged-out header for signed-in users. Render per request.
export const dynamic = "force-dynamic";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "explore" });
  return {
    title: t("title"),
    description: t("subtitle"),
    alternates: localeAlternates(locale, "explore"),
  };
}

export default async function ExplorePage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("explore");
  const [jobs, ratings] = await Promise.all([
    getOpenJobs({ limit: 100 }),
    getCompanyRatings(),
  ]);

  return (
    <div className="relative">
      {/* The map fills the viewport, so the H1 is visually hidden but stays
          in the DOM — SEO + a11y (screen readers announce the page purpose)
          without a header bar competing with the map for space. */}
      <h1 className="sr-only">{t("title")}</h1>
      <JobsMap jobs={jobs} ratings={ratings} fullBleed />
      {/* Floating "list view" escape hatch (bottom-left, clear of near-me). */}
      <Link
        href="/jobs"
        className={cn(
          buttonVariants({ variant: "outline", size: "sm" }),
          "bg-background/95 absolute bottom-6 left-4 z-[1001] gap-1.5 shadow-lg",
        )}
      >
        <List className="size-4" />
        {t("listView")}
      </Link>
    </div>
  );
}
