import type { Metadata } from "next";
import { ArrowLeft, Megaphone } from "lucide-react";
import { notFound, redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { PromoteCreative } from "@/components/employer/promote-creative";
import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { EmptyState } from "@/components/ui/states";
import { getEmployerJobBoost, getMyCompany } from "@/lib/data/employer";
import { requireEmployer } from "@/lib/auth/require-employer";
import { Link } from "@/i18n/navigation";
import { siteUrl } from "@/lib/seo";
import { cn } from "@/lib/utils";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "employer" });
  return { title: t("shareTitle"), robots: { index: false } };
}

// Auth-gated, per-employer. Render per request (see the wallet/dashboard note).
export const dynamic = "force-dynamic";

export default async function ShareJobPage({
  params,
}: {
  params: Promise<{ locale: string; id: string }>;
}) {
  const { locale, id } = await params;
  setRequestLocale(locale);
  await requireEmployer(locale);

  const company = await getMyCompany();
  if (!company) redirect(`/${locale}/employer/onboarding`);

  const [t, job] = await Promise.all([
    getTranslations("employer"),
    // Confirms ownership; null → not theirs / gone.
    getEmployerJobBoost(id),
  ]);
  if (!job) notFound();

  return (
    <Container className="max-w-3xl py-10">
      <Link
        href="/employer/jobs"
        className="text-muted-foreground hover:text-foreground mb-6 inline-flex items-center gap-1 text-sm"
      >
        <ArrowLeft className="size-4" />
        {t("backToJobs")}
      </Link>

      <div className="mb-4 flex items-center gap-3">
        <span className="bg-primary text-primary-foreground flex size-11 shrink-0 items-center justify-center rounded-2xl">
          <Megaphone className="size-5" />
        </span>
        <div className="min-w-0">
          <h1 className="text-foreground text-2xl font-bold">
            {t("shareTitle")}
          </h1>
          <p className="text-muted-foreground truncate text-sm">{job.title}</p>
        </div>
      </div>
      <p className="text-muted-foreground mb-6 text-sm">{t("shareSubtitle")}</p>

      {job.status === "open" ? (
        <PromoteCreative
          basePath={`/${locale}/jobs/${id}`}
          shareUrl={`${siteUrl()}/${locale}/jobs/${id}`}
          title={job.title}
        />
      ) : (
        <EmptyState
          title={t("shareNotPublished")}
          action={
            <Link
              href="/employer/jobs"
              className={cn(buttonVariants({ variant: "primary", size: "sm" }))}
            >
              {t("myJobs")}
            </Link>
          }
        />
      )}
    </Container>
  );
}
