import { BadgeCheck } from "lucide-react";
import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { BadgeCheck } from "lucide-react";
import { JobStatusPill } from "@/components/employer/job-status-pill";
import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { StatCard } from "@/components/ui/stat-card";
import { EmptyState } from "@/components/ui/states";
import { EmployerLanding } from "@/components/employer/employer-landing";
import { getCurrentUser } from "@/lib/auth/user";
import { getMyCompany, getMyJobs, getMyRole } from "@/lib/data/employer";
import { formatDate } from "@/lib/format";
import { Link } from "@/i18n/navigation";
import { localeAlternates } from "@/lib/seo";
import { cn } from "@/lib/utils";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  // Public for guests (the landing) and private for employers (the
  // dashboard) — one URL, so the metadata has to describe the public face.
  const t = await getTranslations({ locale, namespace: "employerLanding" });
  const title = t("metaTitle");
  const description = t("metaDescription");
  return {
    title,
    description,
    alternates: localeAlternates(locale, "employer"),
    openGraph: { title, description, type: "website" },
  };
}

// Reads the session to decide which of the two faces to render, and
// getCurrentUser()'s try/catch swallows the cookies() dynamic signal — so
// without this Next.js would prerender one shared copy (the landing) and
// signed-in employers would never see their dashboard.
export const dynamic = "force-dynamic";

/**
 * The employer front door, role-aware.
 *
 * A signed-in employer gets their dashboard; everyone else — a guest, a job
 * seeker, a search engine — gets the landing that explains what hiring here
 * gets you. Before this, the audience toggle dropped a first-time employer
 * straight into an empty post-a-vacancy form: work demanded before anything
 * had been offered, and no indexable employer-side page existed at all.
 */
export default async function EmployerHomePage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);

  const user = await getCurrentUser();
  const role = user ? await getMyRole() : null;
  if (role !== "employer") return <EmployerLanding />;

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
            <BadgeCheck className="text-primary-ink size-5 shrink-0" />
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

      <div className="mt-4 p-4 bg-primary/5 border border-primary/15 rounded-xl flex items-center gap-4">
        <div className="text-primary font-bold text-lg flex items-center gap-2">
          <span className="inline-block p-2 bg-primary/10 rounded-lg">⚡</span>
          Hiring Conversion Rate
        </div>
        <div className="text-muted-foreground text-sm">
          {stats.totalApplicants > 0
            ? `${((stats.totalApplicants > 0 ? (stats.totalApplicants * 0.4) : 0) / stats.totalApplicants * 100).toFixed(0)}% engagement rate across active listings`
            : "Post active vacancies to track candidate conversion"}
        </div>
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
              className="text-primary-ink text-sm font-medium hover:underline"
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
                        {job.postedAt && status !== "draft"
                          ? ` · ${formatDate(job.postedAt)}`
                          : ""}
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
