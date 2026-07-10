import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { JobStatusPill } from "@/components/employer/job-status-pill";
import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { EmptyState } from "@/components/ui/states";
import { updateJobStatus } from "@/lib/actions/employer";
import { getMyCompany, getMyJobs } from "@/lib/data/employer";
import { requireEmployer } from "@/lib/auth/require-employer";
import { formatDate } from "@/lib/format";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

const actionBtn =
  "text-sm font-medium rounded-lg border border-border px-3 py-1.5 transition-colors hover:bg-muted";

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
  searchParams,
}: {
  params: Promise<{ locale: string }>;
  searchParams: Promise<{
    posted?: string;
    updated?: string;
    promoted?: string;
  }>;
}) {
  const { locale } = await params;
  const { posted, updated, promoted } = await searchParams;
  setRequestLocale(locale);
  await requireEmployer(locale);

  const company = await getMyCompany();
  if (!company) redirect(`/${locale}/employer/onboarding`);

  const t = await getTranslations("employer");
  const jobs = await getMyJobs(company.id);

  const banner = promoted
    ? t("jobPromoted")
    : updated
      ? t("jobUpdated")
      : posted === "draft"
        ? t("draftSaved")
        : posted === "open"
          ? t("jobPosted")
          : null;
  // Right after a job goes LIVE (not a scheduled draft), nudge toward the
  // revenue surface — jobs are ordered newest-first, so jobs[0] is the one
  // that was just published.
  const justPublishedJobId = posted === "open" ? jobs[0]?.id : undefined;

  return (
    <Container className="max-w-3xl py-10">
      {banner ? (
        <div className="border-primary/40 bg-accent mb-5 rounded-xl border px-4 py-3">
          <p className="text-accent-foreground flex items-center gap-2 text-sm font-medium">
            <span aria-hidden>🎉</span>
            {banner}
          </p>
          {justPublishedJobId ? (
            <div className="mt-3 flex flex-wrap gap-2">
              <Link
                href={`/employer/jobs/${justPublishedJobId}/matches`}
                className={cn(
                  buttonVariants({ variant: "primary", size: "sm" }),
                )}
              >
                {t("viewMatches")}
              </Link>
              <Link
                href={`/employer/jobs/${justPublishedJobId}/share`}
                className={cn(
                  buttonVariants({ variant: "outline", size: "sm" }),
                )}
              >
                {t("promoteShare")}
              </Link>
              <Link
                href={`/employer/jobs/${justPublishedJobId}/promote`}
                className={cn(
                  buttonVariants({ variant: "outline", size: "sm" }),
                )}
              >
                {t("promoteThisJob")}
              </Link>
              <Link
                href={`/jobs/${justPublishedJobId}`}
                className={cn(
                  buttonVariants({ variant: "outline", size: "sm" }),
                )}
              >
                {t("viewPublicListing")}
              </Link>
            </div>
          ) : null}
        </div>
      ) : null}

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
            // Owners can't act on an admin-blocked job.
            const canAct = !job.blockedAt;
            return (
              <li
                key={job.id}
                className="border-border bg-card rounded-xl border p-4"
              >
                <div className="flex items-center justify-between gap-3">
                  <Link
                    href={`/employer/jobs/${job.id}/applicants`}
                    className="min-w-0 flex-1"
                  >
                    <p className="text-foreground hover:text-primary truncate font-semibold transition-colors">
                      {job.title}
                    </p>
                    <p className="text-muted-foreground text-sm">
                      {t("applicantsCount", { count: job.applicantsCount })}
                      {job.postedAt && status !== "draft"
                        ? ` · ${formatDate(job.postedAt)}`
                        : ""}
                    </p>
                  </Link>
                  <JobStatusPill
                    status={status}
                    label={
                      t.has(`status.${status}`) ? t(`status.${status}`) : status
                    }
                  />
                </div>
                {canAct &&
                (job.status === "draft" ||
                  job.status === "open" ||
                  job.status === "closed") ? (
                  <div className="border-border mt-3 flex flex-wrap gap-2 border-t pt-3">
                    {job.status === "draft" ? (
                      <StatusForm
                        locale={locale}
                        jobId={job.id}
                        action="publish"
                        label={t("publishDraft")}
                        primary
                      />
                    ) : null}
                    {job.status === "open" ? (
                      <StatusForm
                        locale={locale}
                        jobId={job.id}
                        action="close"
                        label={t("closeJob")}
                      />
                    ) : null}
                    {job.status === "closed" ? (
                      <StatusForm
                        locale={locale}
                        jobId={job.id}
                        action="reopen"
                        label={t("reopenJob")}
                      />
                    ) : null}
                    <Link
                      href={`/employer/jobs/${job.id}/edit`}
                      className={cn(actionBtn, "text-foreground")}
                    >
                      {t("edit")}
                    </Link>
                    {job.status === "open" ? (
                      <Link
                        href={`/employer/jobs/${job.id}/share`}
                        className={cn(actionBtn, "text-foreground")}
                      >
                        {t("promoteShare")}
                      </Link>
                    ) : null}
                    {job.status === "open" ? (
                      <Link
                        href={`/employer/jobs/${job.id}/promote`}
                        className={cn(actionBtn, "text-foreground")}
                      >
                        {t("promote")}
                      </Link>
                    ) : null}
                    <Link
                      href={`/employer/jobs/${job.id}/applicants`}
                      className={cn(actionBtn, "text-foreground")}
                    >
                      {t("viewApplicants")}
                    </Link>
                  </div>
                ) : null}
              </li>
            );
          })}
        </ul>
      )}
    </Container>
  );
}

/** A one-button form that posts a status transition to updateJobStatus. */
function StatusForm({
  locale,
  jobId,
  action,
  label,
  primary,
}: {
  locale: string;
  jobId: string;
  action: "publish" | "close" | "reopen";
  label: string;
  primary?: boolean;
}) {
  return (
    <form action={updateJobStatus}>
      <input type="hidden" name="locale" value={locale} />
      <input type="hidden" name="jobId" value={jobId} />
      <input type="hidden" name="action" value={action} />
      <button
        type="submit"
        className={cn(
          actionBtn,
          primary
            ? "border-primary bg-primary text-primary-foreground hover:opacity-90"
            : "text-foreground",
        )}
      >
        {label}
      </button>
    </form>
  );
}
