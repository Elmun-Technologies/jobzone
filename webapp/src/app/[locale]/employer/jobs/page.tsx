import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { JobStatusPill } from "@/components/employer/job-status-pill";
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

// Auth-gated, per-employer page (reads the session via requireEmployer). Render
// per request — getCurrentUser()'s try/catch swallows the cookies() dynamic
// signal, so without this Next.js would prerender one shared, logged-out copy.
export const dynamic = "force-dynamic";

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
          {jobs.map((job) => {
            // An admin takedown (blocked_at, 0038) trumps the row's own status.
            const status = job.blockedAt ? "blocked" : job.status;
            return (
              <li key={job.id}>
                <Link
                  href={`/employer/jobs/${job.id}/applicants`}
                  className="border-border bg-card hover:border-primary/40 flex items-center justify-between gap-3 rounded-xl border p-4 transition-colors"
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
                  <JobStatusPill
                    status={status}
                    label={
                      t.has(`status.${status}`) ? t(`status.${status}`) : status
                    }
                  />
                </Link>
              </li>
            );
          })}
        </ul>
      )}
    </Container>
  );
}
