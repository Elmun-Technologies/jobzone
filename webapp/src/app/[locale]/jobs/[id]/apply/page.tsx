import type { Metadata } from "next";
import { Clock, Flame, MapPin, Zap } from "lucide-react";
import { notFound } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { ApplyForm } from "@/components/jobs/apply-form";
import { QuickApplyButton } from "@/components/jobs/quick-apply-button";
import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { hasApplied } from "@/lib/data/applications";
import { getJobById } from "@/lib/data/jobs";
import { locationText, salaryText, schedulePatternLabel } from "@/lib/format";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

// Auth/session-dependent, per-request. Without this the page can be
// full-route-cached (getCurrentUser swallows cookies() so Next never sees
// the dynamic signal) and one visitor's render could be served to another.
export const dynamic = "force-dynamic";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "apply" });
  return { title: t("applyTo"), robots: { index: false } };
}

export default async function ApplyPage({
  params,
}: {
  params: Promise<{ locale: string; id: string }>;
}) {
  const { locale, id } = await params;
  setRequestLocale(locale);

  // Guest-first: a visitor can fill this out freely. hasApplied is false for a
  // guest (no user id to match), and applyToJob asks for auth at submit-time.
  const job = await getJobById(id);
  if (!job) notFound();

  const t = await getTranslations("apply");
  const applied = await hasApplied(id);
  // One-tap "apply with my résumé" is offered unless the job needs answers a
  // form must collect (required screening question). The button itself handles
  // sign-in / missing-résumé by routing there and back.
  const needsForm = job.screeningQuestions.some((q) => q.required);

  const salary = salaryText(job);
  const location = locationText(job);
  const schedule = schedulePatternLabel(job.schedulePattern);
  const chips = [
    salary ? { Icon: null, text: salary } : null,
    location ? { Icon: MapPin, text: location } : null,
    schedule ? { Icon: Clock, text: schedule } : null,
    job.categoryName ? { Icon: null, text: job.categoryName } : null,
  ].filter((c): c is { Icon: typeof MapPin | null; text: string } => c != null);

  return (
    <Container className="max-w-2xl py-8">
      <p className="text-muted-foreground text-sm">{t("applyTo")}</p>
      <h1 className="text-foreground text-2xl font-bold">{job.title}</h1>
      <p className="text-muted-foreground">{job.companyName}</p>

      {/* Job at a glance — so the apply page carries the offer, not a bare form. */}
      {chips.length > 0 ? (
        <div className="mt-3 flex flex-wrap gap-2">
          {chips.map((c, i) => (
            <span
              key={i}
              className="border-border bg-card text-foreground inline-flex items-center gap-1.5 rounded-full border px-3 py-1 text-sm font-medium"
            >
              {c.Icon ? (
                <c.Icon className="text-muted-foreground size-3.5" />
              ) : null}
              {c.text}
            </span>
          ))}
        </div>
      ) : null}

      {/* Social proof / urgency — a gentle nudge to apply now. */}
      {!applied ? (
        job.applicantsCount > 0 ? (
          <div className="border-primary/40 bg-accent text-accent-foreground mt-4 flex items-center gap-2 rounded-xl border px-4 py-3 text-sm">
            <Flame className="text-primary size-4 shrink-0" />
            <span className="font-semibold">
              {t("socialProof", { count: job.applicantsCount })}
            </span>
            <span className="text-muted-foreground hidden sm:inline">
              · {t("socialProofNudge")}
            </span>
          </div>
        ) : (
          <div className="border-border bg-card text-foreground mt-4 flex items-center gap-2 rounded-xl border px-4 py-3 text-sm">
            <Zap className="text-primary size-4 shrink-0" />
            <span className="font-medium">{t("beFirst")}</span>
          </div>
        )
      ) : null}

      <div className="mt-6">
        {applied ? (
          <div className="border-border bg-card rounded-xl border p-6 text-center">
            <p className="text-foreground font-medium">{t("alreadyApplied")}</p>
            <Link
              href="/account/applications"
              className={cn(
                buttonVariants({ variant: "primary", size: "md" }),
                "mt-4",
              )}
            >
              {t("viewApplications")}
            </Link>
          </div>
        ) : (
          <>
            {!needsForm ? (
              <div className="mb-6">
                <QuickApplyButton
                  jobId={id}
                  needsForm={false}
                  className="h-12 w-full text-base"
                />
                <p className="text-muted-foreground mt-2 text-center text-sm">
                  {t("quickApplyHint")}
                </p>
                <div className="my-5 flex items-center gap-3">
                  <span className="bg-border h-px flex-1" />
                  <span className="text-muted-foreground text-xs">
                    {t("orAddLetter")}
                  </span>
                  <span className="bg-border h-px flex-1" />
                </div>
              </div>
            ) : null}
            <ApplyForm jobId={id} questions={job.screeningQuestions} />
          </>
        )}
      </div>
    </Container>
  );
}
