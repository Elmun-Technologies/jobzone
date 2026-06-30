import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { EmptyState } from "@/components/ui/states";
import { getMyCompany, getMyJobs } from "@/lib/data/employer";
import { requireEmployer } from "@/lib/auth/require-employer";
import { formatDate } from "@/lib/format";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "employer" });
  return { title: t("myJobs"), robots: { index: false } };
}

const STATUS_CLASS: Record<string, string> = {
  open: "bg-emerald-100 text-emerald-700 dark:bg-emerald-950 dark:text-emerald-300",
  draft: "bg-muted text-muted-foreground",
  closed: "bg-red-100 text-red-700 dark:bg-red-950 dark:text-red-300",
};

export default async function MyJobsPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  await requireEmployer(locale);

  const company = await getMyCompany();
  if (!company) redirect(`/${locale}/employer/onboarding`);

  const t = await getTranslations("employer");
  const jobs = await getMyJobs(company.id);

  return (
    <Container className="max-w-3xl py-10">
      <div className="mb-6 flex items-center justify-between gap-3">
        <h1 className="text-foreground text-2xl font-bold">{t("myJobs")}</h1>
        <Link
          href="/employer/jobs/new"
          className={cn(buttonVariants({ variant: "primary", size: "sm" }))}
        >
          {t("postJob")}
        </Link>
      </div>

      {jobs.length === 0 ? (
        <EmptyState title={t("noJobs")} />
      ) : (
        <ul className="space-y-3">
          {jobs.map((job) => (
            <li
              key={job.id}
              className="border-border bg-card flex items-center justify-between gap-3 rounded-xl border p-4"
            >
              <div className="min-w-0">
                <p className="text-foreground truncate font-semibold">
                  {job.title}
                </p>
                <p className="text-muted-foreground text-sm">
                  {t("applicantsCount", { count: job.applicantsCount })}
                  {job.postedAt ? ` · ${formatDate(job.postedAt)}` : ""}
                </p>
              </div>
              <span
                className={`shrink-0 rounded-full px-2.5 py-1 text-xs font-semibold ${
                  STATUS_CLASS[job.status] ?? STATUS_CLASS.draft
                }`}
              >
                {t.has(`status.${job.status}`)
                  ? t(`status.${job.status}`)
                  : job.status}
              </span>
            </li>
          ))}
        </ul>
      )}
    </Container>
  );
}
