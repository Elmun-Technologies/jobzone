import { Sparkles } from "lucide-react";
import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { JobCard } from "@/components/jobs/job-card";
import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { EmptyState } from "@/components/ui/states";
import { getCurrentUser } from "@/lib/auth/user";
import { getBookmarkedJobIds } from "@/lib/data/bookmarks";
import { getRecommendedJobs } from "@/lib/data/jobs";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "recommended" });
  return { title: t("title"), robots: { index: false } };
}

// Per-user (résumé-driven ranking); render per request.
export const dynamic = "force-dynamic";

export default async function RecommendedJobsPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);

  const user = await getCurrentUser();
  if (!user) redirect(`/${locale}/sign-in`);

  const t = await getTranslations("recommended");
  const [jobs, savedIds] = await Promise.all([
    getRecommendedJobs(),
    getBookmarkedJobIds(),
  ]);

  return (
    <Container className="max-w-2xl py-12">
      <h1 className="text-foreground flex items-center gap-2 text-2xl font-bold">
        <Sparkles className="text-primary size-6" />
        {t("title")}
      </h1>
      <p className="text-muted-foreground mt-1 mb-6 text-sm">{t("subtitle")}</p>

      {jobs.length === 0 ? (
        <EmptyState
          title={t("empty")}
          description={t("emptyHint")}
          action={
            <div className="flex flex-wrap justify-center gap-2">
              <Link
                href="/resumes/new"
                className={cn(
                  buttonVariants({ variant: "primary", size: "sm" }),
                )}
              >
                {t("completeResume")}
              </Link>
              <Link
                href="/jobs"
                className={cn(
                  buttonVariants({ variant: "outline", size: "sm" }),
                )}
              >
                {t("browseAll")}
              </Link>
            </div>
          }
        />
      ) : (
        <ul className="space-y-3">
          {jobs.map((j) => (
            <li key={j.id}>
              <JobCard job={j} saved={savedIds.has(j.id)} />
            </li>
          ))}
        </ul>
      )}
    </Container>
  );
}
