import type { Metadata } from "next";
import { ArrowRight, Check, Sparkles, TrendingUp, Zap } from "lucide-react";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { Container } from "@/components/ui/container";
import { buttonVariants } from "@/components/ui/button";
import { getPromotionProducts, getJobPostPrice } from "@/lib/data/pricing";
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

/** Public "Narxlar" (pricing) marketing page — the employer offer: first
 * vacancy free, then a flat post fee, plus the visibility (reklama) packages.
 * Prices come from the live catalog (fallback offline), so this never drifts
 * from what checkout actually charges. */
export default async function PricingPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);

  const [t, postPrice, products] = await Promise.all([
    getTranslations("pricing"),
    getJobPostPrice(),
    getPromotionProducts(),
  ]);
  const price = postPrice > 0 ? postPrice : 99000;
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

      {/* Posting: first free, then flat fee */}
      <div className="mt-10 grid gap-4 sm:grid-cols-2">
        <div
          className="rise-in border-primary/40 from-accent to-card relative overflow-hidden rounded-3xl border-2 bg-gradient-to-br p-6"
          style={{ animationDelay: "60ms" }}
        >
          <div className="bg-primary/15 absolute -top-8 -right-8 size-28 rounded-full blur-2xl" />
          <span className="text-muted-foreground text-sm font-medium">
            {t("firstPost")}
          </span>
          <p className="text-foreground mt-1 text-4xl font-bold">{t("free")}</p>
          <p className="text-muted-foreground mt-2 text-sm">
            {t("firstPostHint")}
          </p>
        </div>
        <div
          className="rise-in border-border bg-card rounded-3xl border p-6"
          style={{ animationDelay: "120ms" }}
        >
          <span className="text-muted-foreground text-sm font-medium">
            {t("nextPosts")}
          </span>
          <p className="text-foreground mt-1 font-mono text-4xl font-bold tabular-nums">
            {groupNumber(price)}{" "}
            <span className="text-muted-foreground text-xl font-semibold">
              so&apos;m
            </span>
          </p>
          <p className="text-muted-foreground mt-2 text-sm">
            {t("nextPostsHint")}
          </p>
        </div>
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
