import type { Metadata } from "next";
import { ArrowRight, Check, Sparkles, TrendingUp, Zap } from "lucide-react";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { Container } from "@/components/ui/container";
import { buttonVariants } from "@/components/ui/button";
import { getPromotionProducts } from "@/lib/data/pricing";
import { PLAN_TIERS } from "@/lib/pricing-tiers";
import { groupNumber } from "@/lib/format";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "pricing" });
  return {
    title: t("title"),
    description: t("heroSubtitle"),
    alternates: { canonical: `/${locale}/pricing` },
  };
}

// The shared SiteHeader reads the session (getCurrentUser) to show
// account/notifications vs a sign-in button; without this the page was baked
// as static HTML at build time, so a signed-in visitor saw a signed-out
// header here (unlike every other page). Trades SSG for correctness — this
// page isn't a primary organic-search surface, unlike the job/category pages.
export const dynamic = "force-dynamic";

/** Public "Narxlar" (pricing) marketing page — the employer offer: plans priced
 * by how many active vacancies you run (first one free), plus the per-vacancy
 * visibility (reklama) packages as add-ons. The plan tiers are the single
 * source of truth in `pricing-tiers.ts`; the boost prices come from the live
 * catalog (fallback offline) so they never drift from what checkout charges. */
export default async function PricingPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);

  const [t, products] = await Promise.all([
    getTranslations("pricing"),
    getPromotionProducts(),
  ]);
  const perDay = (p: (typeof products)[number]) =>
    p.priceUzs / Math.max(p.durationDays, 1);
  const bestCode = products.length
    ? products.reduce((a, b) => (perDay(b) < perDay(a) ? b : a)).code
    : "";
  // Per-day discount of each TOP tier vs the priciest TOP tier — the longer,
  // the cheaper (featured is a different benefit, excluded).
  const maxTopPerDay = products
    .filter((p) => p.kind === "top")
    .reduce((m, p) => Math.max(m, perDay(p)), 0);
  const savingsOf = (p: (typeof products)[number]) =>
    p.kind === "top" && maxTopPerDay > 0
      ? Math.round((1 - perDay(p) / maxTopPerDay) * 100)
      : 0;

  const benefits = [
    { Icon: Zap, title: t("benefit1Title"), desc: t("benefit1Desc") },
    { Icon: TrendingUp, title: t("benefit2Title"), desc: t("benefit2Desc") },
    { Icon: Check, title: t("benefit3Title"), desc: t("benefit3Desc") },
  ];

  return (
    <Container className="max-w-4xl py-12">
      {/* Hero */}
      <div className="rise-in text-center">
        <h1 className="text-foreground text-3xl font-bold sm:text-4xl">
          {t("heroTitle")}
        </h1>
        <p className="text-muted-foreground mx-auto mt-3 max-w-xl text-base sm:text-lg">
          {t("heroSubtitle")}
        </p>
      </div>

      {/* Plans priced by how many active vacancies you run — first one free */}
      <div className="mt-10">
        <div className="mb-5 text-center">
          <h2 className="text-foreground text-2xl font-bold">
            {t("tiers.heading")}
          </h2>
          <p className="text-muted-foreground mt-1 text-sm">
            {t("tiers.subheading")}
          </p>
        </div>
        <ul className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {PLAN_TIERS.map((tier, i) => {
            const isFree = tier.priceUzs <= 0;
            return (
              <li
                key={tier.code}
                className={cn(
                  "rise-in relative flex flex-col rounded-3xl border p-6",
                  tier.featured
                    ? "border-primary ring-primary/20 bg-accent ring-2"
                    : "border-border bg-card",
                )}
                style={{ animationDelay: `${60 + i * 70}ms` }}
              >
                {tier.featured ? (
                  <span className="bg-primary text-primary-foreground absolute -top-3 left-1/2 -translate-x-1/2 rounded-full px-3 py-0.5 text-[11px] font-bold tracking-wide uppercase">
                    {t("tiers.popular")}
                  </span>
                ) : null}
                <span className="text-foreground text-lg font-bold">
                  {t(`tiers.${tier.code}.name`)}
                </span>
                <span className="text-muted-foreground mt-0.5 text-sm">
                  {t(`tiers.${tier.code}.cap`)}
                </span>
                <p className="mt-4">
                  {isFree ? (
                    <span className="text-foreground text-3xl font-bold">
                      {t("free")}
                    </span>
                  ) : (
                    <>
                      <span className="text-foreground font-mono text-3xl font-bold tabular-nums">
                        {groupNumber(tier.priceUzs)}
                      </span>
                      <span className="text-muted-foreground ml-1 text-sm font-semibold">
                        so&apos;m
                      </span>
                    </>
                  )}
                </p>
                <p className="text-muted-foreground mt-3 flex-1 text-sm">
                  {t(`tiers.${tier.code}.desc`)}
                </p>
                <Link
                  href="/employer/jobs/new"
                  className={cn(
                    buttonVariants({
                      variant: tier.featured ? "primary" : "outline",
                      size: "sm",
                    }),
                    "mt-5 w-full",
                  )}
                >
                  {isFree ? t("tiers.ctaFree") : t("tiers.cta")}
                </Link>
              </li>
            );
          })}
        </ul>
      </div>

      {/* Promotion packages */}
      <div className="mt-12">
        <h2 className="text-foreground text-2xl font-bold">
          {t("promoTitle")}
        </h2>
        <p className="text-muted-foreground mt-1 text-sm">
          {t("promoSubtitle")}
        </p>
        <ul className="mt-5 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          {products.map((p, i) => {
            const isBest = p.code === bestCode;
            const Icon = p.kind === "featured" ? Sparkles : TrendingUp;
            return (
              <li
                key={p.code}
                className={cn(
                  "rise-in relative flex flex-col gap-1 overflow-hidden rounded-2xl border p-4",
                  isBest
                    ? "border-primary ring-primary/20 bg-accent ring-2"
                    : "border-border bg-card",
                )}
                style={{ animationDelay: `${150 + i * 70}ms` }}
              >
                {isBest ? (
                  <span className="bg-primary text-primary-foreground absolute top-0 right-0 rounded-bl-xl px-2.5 py-0.5 text-[11px] font-bold tracking-wide uppercase">
                    {t("bestValue")}
                  </span>
                ) : null}
                <span className="flex items-center gap-2">
                  <Icon className="text-primary size-4 shrink-0" />
                  <span className="text-foreground font-semibold">
                    {p.name}
                  </span>
                </span>
                {p.description ? (
                  <span className="text-muted-foreground text-sm">
                    {p.description}
                  </span>
                ) : null}
                <span className="text-foreground mt-1 font-mono text-2xl font-bold tabular-nums">
                  {groupNumber(p.priceUzs)}
                  <span className="text-muted-foreground ml-1 text-sm font-semibold">
                    so&apos;m
                  </span>
                </span>
                <span className="text-muted-foreground flex items-center justify-between text-xs">
                  <span className="flex items-center gap-1.5">
                    {t("duration", { days: p.durationDays })}
                    {savingsOf(p) > 0 ? (
                      <span className="rounded bg-emerald-100 px-1.5 py-0.5 font-semibold text-emerald-700 dark:bg-emerald-950 dark:text-emerald-300">
                        {t("cheaper", { pct: savingsOf(p) })}
                      </span>
                    ) : null}
                  </span>
                  <span className="font-medium">
                    {t("perDay", { price: groupNumber(Math.round(perDay(p))) })}
                  </span>
                </span>
              </li>
            );
          })}
        </ul>
      </div>

      {/* Why Yolla */}
      <div className="mt-12 grid gap-3 sm:grid-cols-3">
        {benefits.map((b, i) => (
          <div
            key={b.title}
            className="rise-in border-border bg-card rounded-2xl border p-5"
            style={{ animationDelay: `${i * 80}ms` }}
          >
            <b.Icon className="text-primary size-5" />
            <p className="text-foreground mt-2 font-semibold">{b.title}</p>
            <p className="text-muted-foreground mt-1 text-sm">{b.desc}</p>
          </div>
        ))}
      </div>

      {/* CTA band */}
      <div className="bg-primary text-primary-foreground mt-12 flex flex-col items-center gap-4 rounded-3xl px-6 py-10 text-center">
        <h2 className="text-2xl font-bold sm:text-3xl">{t("ctaTitle")}</h2>
        <p className="max-w-md text-sm opacity-90 sm:text-base">
          {t("ctaText")}
        </p>
        <Link
          href="/employer/jobs/new"
          className={cn(
            buttonVariants({ variant: "outline", size: "lg" }),
            "border-primary-foreground/30 bg-background text-foreground hover:bg-background/90 gap-2",
          )}
        >
          {t("ctaButton")}
          <ArrowRight className="size-4" />
        </Link>
      </div>
    </Container>
  );
}
