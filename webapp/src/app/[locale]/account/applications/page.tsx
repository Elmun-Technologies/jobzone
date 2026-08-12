import { CheckCircle2 } from "lucide-react";
import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { WithdrawApplicationButton } from "@/components/account/withdraw-application-button";
import { buttonVariants } from "@/components/ui/button";
import { Celebrate } from "@/components/ui/celebrate";
import { Container } from "@/components/ui/container";
import { EmptyState } from "@/components/ui/states";
import { getMyApplications } from "@/lib/data/applications";
import { formatDate } from "@/lib/format";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "applications" });
  return { title: t("title"), robots: { index: false } };
}

// Per-user page (reads the session inside getMyApplications, whose catch
// swallows the cookies() dynamic signal). Without this Next.js statically
// bakes the guest render — a permanently empty list for signed-in users.
export const dynamic = "force-dynamic";

// Tailwind classes per status (amber/green/red/etc.).
const STATUS_CLASS: Record<string, string> = {
  submitted: "bg-muted text-muted-foreground",
  viewed: "bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-300",
  shortlisted: "bg-accent text-accent-foreground",
  interview:
    "bg-amber-100 text-amber-700 dark:bg-amber-950 dark:text-amber-300",
  offer:
    "bg-emerald-100 text-emerald-700 dark:bg-emerald-950 dark:text-emerald-300",
  rejected: "bg-red-100 text-red-700 dark:bg-red-950 dark:text-red-300",
  hired:
    "bg-emerald-100 text-emerald-700 dark:bg-emerald-950 dark:text-emerald-300",
  // 0059 added this status but the web knew nothing about it, so an
  // application withdrawn on mobile rendered the raw word "withdrawn" in
  // "submitted" grey.
  withdrawn: "bg-muted text-muted-foreground line-through",
};

/** Statuses past which withdrawing is pointless or impossible. */
const FINAL_STATUSES = new Set(["withdrawn", "rejected", "hired"]);

export default async function MyApplicationsPage({
  params,
  searchParams,
}: {
  params: Promise<{ locale: string }>;
  searchParams: Promise<{ applied?: string }>;
}) {
  const { locale } = await params;
  const { applied } = await searchParams;
  setRequestLocale(locale);
  const t = await getTranslations("applications");
  const apps = await getMyApplications();
  // The full apply form (apply.ts:applyToJob) redirects here with ?applied=1 —
  // the seeker just typed a cover letter / answered screening questions and
  // deserves a clear "it worked", not a silent landing on a generic list.
  const justApplied = applied === "1" && apps.length > 0;

  return (
    <Container className="max-w-2xl py-12">
      <h1 className="text-foreground mb-6 text-2xl font-bold">{t("title")}</h1>

      {justApplied ? (
        <div className="border-primary/40 bg-accent text-accent-foreground success-pop mb-6 flex items-center gap-2 rounded-xl border p-4 text-sm font-medium">
          {/* Sends the confirmation chime — the seeker landed here from a
              redirect, so the tap that earned it is already gone. */}
          <Celebrate />
          <CheckCircle2 className="text-foreground size-5 shrink-0" />
          {t("appliedBanner")}
        </div>
      ) : null}

      {apps.length === 0 ? (
        <EmptyState
          title={t("empty")}
          description={t("emptyHint")}
          action={
            <Link
              href="/jobs"
              className={cn(buttonVariants({ variant: "primary", size: "sm" }))}
            >
              {t("browseJobs")}
            </Link>
          }
        />
      ) : (
        <ul className="space-y-3">
          {apps.map((a) => {
            // A closed (or otherwise gone) job still gets a card — this is
            // exactly the record an applicant hired for a now-filled position
            // needs to keep — but it isn't a live listing, so no /jobs/ link.
            const isOpen = a.jobStatus === "open";
            const cardClass =
              "border-border bg-card flex items-center justify-between gap-3 rounded-xl border p-4 transition-colors";
            const content = (
              <>
                <div className="min-w-0">
                  <p className="text-foreground truncate font-semibold">
                    {a.jobTitle}
                  </p>
                  <p className="text-muted-foreground truncate text-sm">
                    {a.companyName}
                    {a.appliedAt ? ` · ${formatDate(a.appliedAt)}` : ""}
                    {!isOpen ? ` · ${t("positionClosed")}` : ""}
                  </p>
                </div>
                <span
                  className={`shrink-0 rounded-full px-2.5 py-1 text-xs font-semibold ${
                    STATUS_CLASS[a.status] ?? STATUS_CLASS.submitted
                  }`}
                >
                  {t.has(`status.${a.status}`)
                    ? t(`status.${a.status}`)
                    : a.status}
                </span>
              </>
            );
            const canWithdraw = !FINAL_STATUSES.has(a.status);
            return (
              <li key={a.id}>
                {isOpen ? (
                  <Link
                    href={`/jobs/${a.jobId}`}
                    className={cn(cardClass, "hover:border-primary/40")}
                  >
                    {content}
                  </Link>
                ) : (
                  <div className={cardClass}>{content}</div>
                )}
                {/* Outside the card: the card is a link to the vacancy, and a
                    button nested in an anchor is neither valid nor clickable
                    the way a user expects. */}
                {canWithdraw ? (
                  <div className="mt-1 flex justify-end pr-1">
                    <WithdrawApplicationButton applicationId={a.id} />
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
