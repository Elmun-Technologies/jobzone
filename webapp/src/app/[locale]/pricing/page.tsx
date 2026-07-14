import type { Metadata } from "next";
import { ArrowRight, Check, Sparkles, TrendingUp, Zap } from "lucide-react";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { Container } from "@/components/ui/container";
import { buttonVariants } from "@/components/ui/button";
import { LISTING_TIERS } from "@/lib/listing-tiers";
import { groupNumber } from "@/lib/format";
import { Link } from "@/i18n/navigation";
import { localeAlternates } from "@/lib/seo";
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
    alternates: localeAlternates(locale, "pricing"),
  };
}

// The shared SiteHeader reads the session (getCurrentUser) to show
// account/notifications vs a sign-in button; without this the page was baked
// as static HTML at build time, so a signed-in visitor saw a signed-out
// header here (unlike every other page). Trades SSG for correctness — this
// page isn't a primary organic-search surface, unlike the job/category pages.
export const dynamic = "force-dynamic";

/** Public "Narxlar" (pricing) marketing page — the employer offer: the first
 * vacancy is free, then every listing picks one of three per-listing
 * visibility tiers (Standart / Brend / Premium). The copy leans employers
 * toward the two paid-up tiers; the tier prices are the single source of truth
 * in `listing-tiers.ts`, matched by the post-time picker + catalog. */
export default async function PricingPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);

  const t = await getTranslations("pricing");

  const benefits = [
    { Icon: Zap, title: t("benefit1Title"), desc: t("benefit1Desc") },
    { Icon: TrendingUp, title: t("benefit2Title"), desc: t("benefit2Desc") },
    { Icon: Check, title: t("benefit3Title"), desc: t("benefit3Desc") },
  ];

  return (
    <Container className="max-w-5xl py-12">
      {/* Hero */}
      <div className="rise-in text-center">
        <h1 className="text-foreground text-3xl font-bold sm:text-4xl">
          {t("heroTitle")}
        </h1>
        <p className="text-muted-foreground mx-auto mt-3 max-w-xl text-base sm:text-lg">
          {t("heroSubtitle")}
        </p>
        <p className="border-primary/40 bg-accent text-foreground mt-5 inline-flex items-center gap-1.5 rounded-full border px-3 py-1 text-sm font-semibold">
          <Sparkles className="text-primary size-4" />
          {t("tiers.firstFree")}
        </p>
      </div>

      {/* Per-listing tiers */}
      <div className="mt-10">
        <div className="mb-6 text-center">
          <h2 className="text-foreground text-2xl font-bold">
            {t("tiers.heading")}
          </h2>
          <p className="text-muted-foreground mx-auto mt-1 max-w-xl text-sm">
            {t("tiers.sub")}
          </p>
        </div>
        <ul className="grid items-stretch gap-4 lg:grid-cols-3">
          {LISTING_TIERS.map((tier, i) => {
            const isPremium = tier.code === "premium";
            const isBrand = tier.code === "brand";
            const emphasized = isBrand || isPremium;
            return (
              <li
                key={tier.code}
                className={cn(
                  "rise-in relative flex flex-col overflow-hidden rounded-3xl border p-6",
                  isPremium
                    ? "border-primary from-primary/10 to-card bg-gradient-to-br"
                    : isBrand
                      ? "border-primary ring-primary/20 bg-accent ring-2"
                      : "border-border bg-card",
                )}
                style={{ animationDelay: `${60 + i * 80}ms` }}
              >
                {isPremium ? (
                  <div className="bg-primary/20 absolute -top-10 -right-10 size-32 rounded-full blur-2xl" />
                ) : null}
                {emphasized ? (
                  <span className="bg-primary text-primary-foreground absolute top-0 right-0 rounded-bl-xl px-2.5 py-0.5 text-[11px] font-bold tracking-wide uppercase">
                    {t(`tiers.${tier.code}.badge`)}
                  </span>
                ) : null}
                <span className="text-foreground text-lg font-bold">
                  {t(`tiers.${tier.code}.name`)}
                </span>
                <span className="text-muted-foreground mt-0.5 text-sm">
                  {t(`tiers.${tier.code}.tagline`)}
                </span>
                <p className="mt-4">
                  <span className="text-foreground font-mono text-3xl font-bold tabular-nums">
                    {groupNumber(tier.priceUzs)}
                  </span>
                  <span className="text-muted-foreground ml-1 text-sm font-semibold">
                    so&apos;m
                  </span>
                </p>
                <ul className="mt-4 flex flex-col gap-2">
                  {["f1", "f2", "f3"].map((f) => (
                    <li
                      key={f}
                      className="text-foreground flex items-start gap-2 text-sm"
                    >
                      <Check className="text-primary mt-0.5 size-4 shrink-0" />
                      {t(`tiers.${tier.code}.${f}`)}
                    </li>
                  ))}
                </ul>
                <p
                  className={cn(
                    "mt-4 rounded-xl px-3 py-2 text-xs font-medium",
                    emphasized
                      ? "bg-primary/15 text-foreground"
                      : "bg-muted text-muted-foreground",
                  )}
                >
                  {t(`tiers.${tier.code}.angle`)}
                </p>
                <Link
                  href="/employer/jobs/new"
                  className={cn(
                    buttonVariants({
                      variant: emphasized ? "primary" : "outline",
                      size: "sm",
                    }),
                    "mt-5 w-full",
                  )}
                >
                  {t("tiers.cta")}
                </Link>
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
