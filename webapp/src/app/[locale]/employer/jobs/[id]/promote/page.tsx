import type { Metadata } from "next";
import { BadgeCheck, Eye, MapPin, Megaphone, Sparkles } from "lucide-react";
import { notFound, redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { Container } from "@/components/ui/container";
import { EmptyState } from "@/components/ui/states";
import { UpgradeForm } from "@/components/employer/upgrade-form";
import { buttonVariants } from "@/components/ui/button";
import { getEmployerJobBoost, getMyCompany } from "@/lib/data/employer";
import { requireEmployer } from "@/lib/auth/require-employer";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "promote" });
  return { title: t("title"), robots: { index: false } };
}

// Auth-gated, per-employer. Render per request (see the wallet/dashboard note).
export const dynamic = "force-dynamic";

/**
 * "Reklama" for a vacancy that is already live: upgrade its listing tier.
 *
 * Until 0075 this page sold the old time-boxed TOP/featured boosts from the
 * Hamyon balance — but 0063 deactivated every one of those products, so the
 * catalog read came back empty by construction and the page rendered a pitch,
 * no packages, and a "top up the wallet — 0 so'm" button. Every open vacancy
 * linked here, so this was the employer's most reachable dead end.
 *
 * Now it sells the same three tiers as the post-time picker, minus the ones
 * the listing already has, through the same Payme/Click/Rahmat checkout.
 */
export default async function PromoteJobPage({
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
    getTranslations("promote"),
    getEmployerJobBoost(id),
  ]);
  // getEmployerJobBoost already confirmed ownership; null → not theirs / gone.
  if (!job) notFound();

  // A draft is not "promoted" — it is published-and-paid, which is /pay's job.
  // Sending them there beats telling them to publish first and then come back.
  if (job.status === "draft") redirect(`/${locale}/employer/jobs/${id}/pay`);

  const currentTier =
    job.boostKind === "premium"
      ? "premium"
      : job.boostKind === "brand"
        ? "brand"
        : null;
  const atTop = currentTier === "premium";

  const benefits = [
    { Icon: BadgeCheck, label: t("benefitStandOut") },
    { Icon: Eye, label: t("benefitViews") },
    { Icon: MapPin, label: t("benefitMap") },
  ];

  return (
    <Container className="max-w-2xl py-10">
      {/* Hero — a compelling pitch, not a bare form header. */}
      <div className="rise-in border-primary/30 from-accent to-card relative mb-6 overflow-hidden rounded-3xl border bg-gradient-to-br p-6 sm:p-8">
        <div className="bg-primary/15 absolute -top-10 -right-10 size-36 rounded-full blur-2xl" />
        <div className="relative">
          <div className="mb-3 flex items-center gap-2">
            <span className="bg-primary text-primary-foreground flex size-10 shrink-0 items-center justify-center rounded-2xl">
              <Megaphone className="size-5" />
            </span>
            <span className="text-muted-foreground truncate text-sm font-medium">
              {t("forJob", { title: job.title })}
            </span>
          </div>
          <h1 className="text-foreground text-2xl font-bold sm:text-3xl">
            {t("heroTitle")}
          </h1>
          <p className="text-muted-foreground mt-2 max-w-lg text-sm sm:text-base">
            {t("heroSubtitle")}
          </p>
        </div>
      </div>

      {job.status !== "open" ? (
        <>
          <EmptyState
            title={t("notOpenTitle")}
            description={t("notOpenHint")}
          />
          <div className="mt-4 flex justify-center">
            <Link
              href="/employer/jobs"
              className={cn(buttonVariants({ variant: "outline", size: "sm" }))}
            >
              {t("back")}
            </Link>
          </div>
        </>
      ) : atTop ? (
        <>
          <EmptyState title={t("atTopTitle")} description={t("atTopHint")} />
          <div className="mt-4 flex justify-center gap-2">
            <Link
              href={`/employer/jobs/${job.id}/share`}
              className={cn(buttonVariants({ variant: "primary", size: "sm" }))}
            >
              {t("shareInstead")}
            </Link>
            <Link
              href="/employer/jobs"
              className={cn(buttonVariants({ variant: "outline", size: "sm" }))}
            >
              {t("back")}
            </Link>
          </div>
        </>
      ) : (
        <>
          {/* Value props */}
          <div className="mb-6 grid gap-3 sm:grid-cols-3">
            {benefits.map((b, i) => (
              <div
                key={b.label}
                className="rise-in border-border bg-card flex items-center gap-3 rounded-2xl border p-4"
                style={{ animationDelay: `${i * 80}ms` }}
              >
                <b.Icon className="text-primary-ink size-5 shrink-0" />
                <span className="text-foreground text-sm font-medium">
                  {b.label}
                </span>
              </div>
            ))}
          </div>

          {/* Where they are today, so the upgrade reads as a step up. */}
          <div className="border-border bg-card mb-5 flex items-center justify-between rounded-xl border px-4 py-3 text-sm">
            <span className="text-muted-foreground">{t("currentTier")}</span>
            <span className="text-foreground inline-flex items-center gap-1.5 font-semibold">
              {currentTier === "brand" ? (
                <Sparkles className="text-primary size-4" />
              ) : null}
              {currentTier === "brand" ? t("tierBrand") : t("tierBase")}
            </span>
          </div>

          <UpgradeForm jobId={job.id} currentTier={currentTier} />
        </>
      )}
    </Container>
  );
}
