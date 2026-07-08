import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { ApplyForm } from "@/components/jobs/apply-form";
import { QuickApplyButton } from "@/components/jobs/quick-apply-button";
import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { hasApplied } from "@/lib/data/applications";
import { getJobById } from "@/lib/data/jobs";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

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

  return (
    <Container className="max-w-2xl py-8">
      <p className="text-muted-foreground text-sm">{t("applyTo")}</p>
      <h1 className="text-foreground text-2xl font-bold">{job.title}</h1>
      <p className="text-muted-foreground mb-6">{job.companyName}</p>

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
    </Container>
  );
}
