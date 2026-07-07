import { BadgeCheck } from "lucide-react";
import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { JobStatusPill } from "@/components/employer/job-status-pill";
import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { StatCard } from "@/components/ui/stat-card";
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
  return { title: t("dashboard"), robots: { index: false } };
}

// Auth-gated, per-employer page (reads the session via requireEmployer). Render
// per request — getCurrentUser()'s try/catch swallows the cookies() dynamic
// signal, so without this Next.js would prerender one shared, logged-out copy.
export const dynamic = "force-dynamic";

export default async function EmployerDashboardPage({
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
  const tw = await getTranslations("wallet");
  // One query for everything on this page — getEmployerStats() would just
  // re-run the same getMyJobs() call internally to compute the same numbers.
  const jobs = await getMyJobs(company.id);
  const stats = {
    totalJobs: jobs.length,
    openJobs: jobs.filter((j) => j.status === "open").length,
    totalApplicants: jobs.reduce((sum, j) => sum + j.applicantsCount, 0),
  };
  const recentJobs = jobs.slice(0, 5);

  return (
    <Container className="py-10">
      <p className="text-muted-foreground text-sm">{t("dashboard")}</p>
      <div className="mt-1 flex items-center gap-2.5">
        {company.logoUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={company.logoUrl}
            alt={company.name}
            width={40}
            height={40}
            className="size-10 shrink-0 rounded-lg object-cover"
          />
        ) : (
          <div className="bg-primary text-primary-foreground flex size-10 shrink-0 items-center justify-center rounded-lg text-base font-bold">
            {company.name.charAt(0).toUpperCase()}
          </div>
        )}
        <h1 className="text-foreground flex items-center gap-1.5 text-2xl font-bold">
          {company.name}
          {company.isVerified ? (
            <BadgeCheck className="text-primary size-5 shrink-0" />
          ) : null}
        </h1>
      </div>

      <div className="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-3">
        <StatCard
          label={t("statOpenJobs")}
          value={stats.openJobs}
          href="/employer/jobs"
        />
        <StatCard label={t("statApplicants")} value={stats.totalApplicants} />
        <StatCard
          label={t("statJobs")}
          value={stats.totalJobs}
          href="/employer/jobs"
        />
      </div>

      <div className="mt-8 flex flex-wrap gap-3">
        <Link
          href="/employer/jobs/new"
          className={cn(buttonVariants({ variant: "primary", size: "md" }))}
        >
          {t("postJob")}
        </Link>
        <Link
          href="/employer/jobs"
          className={cn(buttonVariants({ variant: "outline", size: "md" }))}
        >
          {t("myJobs")}
        </Link>
        <Link
          href="/employer/wallet"
          className={cn(buttonVariants({ variant: "outline", size: "md" }))}
        >
          {tw("title")}
        </Link>
        <Link
          href="/employer/company/edit"
          className={cn(buttonVariants({ variant: "ghost", size: "md" }))}
        >
          {t("editCompany")}
        </Link>
      </div>

      <div className="mt-10">
        <div className="flex items-center justify-between">
          <h2 className="text-foreground text-lg font-bold">
            {t("recentJobs")}
          </h2>
          {jobs.length > recentJobs.length ? (
            <Link
              href="/employer/jobs"
              className="text-primary text-sm font-medium hover:underline"
            >
              {t("viewAll")}
            </Link>
          ) : null}
        </div>
        {recentJobs.length === 0 ? (
          <div className="mt-3">
            <EmptyState title={t("noJobs")} />
          </div>
        ) : (
          <ul className="mt-3 space-y-2">
            {recentJobs.map((job) => {
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
                        t.has(`status.${status}`)
                          ? t(`status.${status}`)
                          : status
                      }
                    />
                  </Link>
                </li>
              );
            })}
          </ul>
        )}
      </div>
    </Container>
  );
}
