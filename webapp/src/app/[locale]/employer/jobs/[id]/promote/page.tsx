import type { Metadata } from "next";
import { ArrowUpToLine, Eye, Megaphone, Sparkles } from "lucide-react";
import { notFound, redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { PromotePicker } from "@/components/employer/promote-picker";
import { Container } from "@/components/ui/container";
import { EmptyState } from "@/components/ui/states";
import { buttonVariants } from "@/components/ui/button";
import { getEmployerJobBoost, getMyCompany } from "@/lib/data/employer";
import { getPromotionProducts } from "@/lib/data/pricing";
import { getWallet } from "@/lib/data/wallet";
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
  const t = await getTranslations({ locale, namespace: "promote" });
  return { title: t("title"), robots: { index: false } };
}

// Auth-gated, per-employer. Render per request (see the wallet/dashboard note).
export const dynamic = "force-dynamic";

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

  const [t, job, products, wallet] = await Promise.all([
    getTranslations("promote"),
    getEmployerJobBoost(id),
    getPromotionProducts(),
    getWallet(company.id),
  ]);
  // getEmployerJobBoost already confirmed ownership; null → not theirs / gone.
  if (!job) notFound();

  const benefits = [
    { Icon: ArrowUpToLine, label: t("benefitTop") },
    { Icon: Eye, label: t("benefitViews") },
    { Icon: Sparkles, label: t("benefitFeatured") },
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
                <b.Icon className="text-primary size-5 shrink-0" />
                <span className="text-foreground text-sm font-medium">
                  {b.label}
                </span>
              </div>
            ))}
          </div>

          {job.boostActive ? (
            <div className="border-primary/40 bg-accent text-accent-foreground mb-6 rounded-xl border px-4 py-3 text-sm font-medium">
              {t("activeUntil", { date: formatDate(job.boostedUntil) })}
            </div>
          ) : null}

          <PromotePicker
            jobId={job.id}
            jobTitle={job.title}
            locale={locale}
            products={products}
            balanceUzs={wallet.balanceUzs}
          />
        </>
      )}
    </Container>
  );
}
