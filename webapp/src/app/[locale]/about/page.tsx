import {
  ArrowRight,
  BadgeCheck,
  Building2,
  Check,
  MapPin,
  Send,
  Sparkles,
} from "lucide-react";
import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { HowItWorks } from "@/components/landing/how-it-works";
import { Eyebrow, RatingCard, SectionHead } from "@/components/landing/section";
import { JobsMap } from "@/components/map/jobs-map";
import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { getCompanyRatings } from "@/lib/data/companies";
import { getOpenJobs } from "@/lib/data/jobs";
import { Link } from "@/i18n/navigation";
import { localeAlternates } from "@/lib/seo";
import { cn } from "@/lib/utils";

/** Guest-first post-vacancy route (carved out of the employer gate). */
const POST_HREF = "/employer/jobs/new";
/** Placeholder author contact — swap for a real Telegram/email before launch. */
const WRITE_HREF = "mailto:info@yolla.uz";
const COORDS = "41.2995°N 69.2401°E · TOSHKENT";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "landing" });
  return {
    title: t("meta.title"),
    description: t("meta.description"),
    alternates: localeAlternates(locale, "about"),
  };
}

// Two reasons: the shared SiteHeader reads the session (getCurrentUser), so a
// static build baked a signed-out header here for every visitor; and this
// page's map reads the live job feed (getOpenJobs) the same way the homepage
// did before eb3f9c0 — frozen at build time otherwise, so new postings never
// appeared here (invariant #3).
export const dynamic = "force-dynamic";

export default async function AboutPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("landing");
  const [jobs, ratings] = await Promise.all([
    getOpenJobs({ limit: 100 }),
    getCompanyRatings(),
  ]);

  return (
    <>
      {/* ── Hero ─────────────────────────────────────────────────────── */}
      <section className="border-border border-b">
        <Container className="py-16 sm:py-24">
          <div className="mx-auto flex max-w-3xl flex-col items-center gap-6 text-center">
            <span className="border-border bg-muted text-muted-foreground inline-flex items-center gap-2 rounded-full border px-3 py-1 font-mono text-xs font-semibold tracking-wide uppercase">
              <MapPin className="text-primary size-3.5" />
              {t("hero.badge")}
            </span>
            <h1 className="text-foreground text-4xl font-bold tracking-tight text-balance sm:text-6xl">
              {t("hero.title")}
            </h1>
            <p className="text-muted-foreground max-w-2xl text-lg text-pretty">
              {t("hero.subtitle")}
            </p>
            <div className="mt-2 flex flex-col gap-3 sm:flex-row">
              <a
                href="#map"
                className={cn(
                  buttonVariants({ variant: "primary", size: "lg" }),
                )}
              >
                {t("hero.ctaFind")}
              </a>
              <Link
                href={POST_HREF}
                className={cn(
                  buttonVariants({ variant: "outline", size: "lg" }),
                )}
              >
                {t("hero.ctaPost")}
              </Link>
            </div>
            <p className="text-muted-foreground flex items-center gap-1.5 text-sm">
              <Check className="text-primary size-4" />
              {t("hero.free")}
            </p>
          </div>
        </Container>
      </section>

      {/* ── The map (the focus) ──────────────────────────────────────── */}
      <section id="map" className="scroll-mt-16">
        <Container className="py-16 sm:py-20">
          <div className="mx-auto mb-8 max-w-3xl text-center">
            <Eyebrow>{t("map.eyebrow")}</Eyebrow>
            <h2 className="text-foreground mt-3 text-3xl font-bold tracking-tight sm:text-4xl">
              {t("map.title")}
            </h2>
            <p className="text-muted-foreground mx-auto mt-4 max-w-2xl text-pretty">
              {t("map.body")}
            </p>
          </div>

          <JobsMap jobs={jobs} ratings={ratings} height="72vh" />

          <p className="text-muted-foreground mt-3 text-center font-mono text-xs tracking-wide">
            {COORDS} · {t("map.hint")}
          </p>

          {/* Feed vs. map contrast */}
          <div className="mt-12 grid gap-4 md:grid-cols-2">
            <div className="border-border bg-muted/40 rounded-2xl border p-6">
              <div className="mb-4 flex items-baseline justify-between gap-3">
                <h3 className="text-foreground font-semibold">
                  {t("map.feedTitle")}
                </h3>
                <span className="text-muted-foreground font-mono text-xs tracking-wide uppercase">
                  {t("map.feedTag")}
                </span>
              </div>
              <div className="space-y-2" aria-hidden>
                {[0, 1, 2, 3].map((i) => (
                  <div
                    key={i}
                    className="bg-background/60 border-border/60 h-8 rounded-lg border"
                  />
                ))}
              </div>
              <p className="text-muted-foreground mt-4 text-sm">
                {t("map.feedBody")}
              </p>
            </div>

            <div className="border-primary/40 bg-card ring-primary/10 rounded-2xl border p-6 ring-1">
              <div className="mb-4 flex items-baseline justify-between gap-3">
                <h3 className="text-foreground font-semibold">
                  {t("map.mapTitle")}
                </h3>
                <span className="text-primary font-mono text-xs tracking-wide uppercase">
                  {t("map.mapTag")}
                </span>
              </div>
              <div className="flex flex-wrap gap-2" aria-hidden>
                {["400 m", "900 m", "1,3 km"].map((d) => (
                  <span
                    key={d}
                    className="border-border bg-muted text-foreground inline-flex items-center gap-1.5 rounded-full border px-3 py-1.5 font-mono text-sm font-semibold"
                  >
                    <MapPin className="text-primary size-3.5" />
                    {d}
                  </span>
                ))}
              </div>
              <p className="text-muted-foreground mt-4 text-sm">
                {t("map.mapBody")}
              </p>
            </div>
          </div>
        </Container>
      </section>

      {/* ── How it works (3 steps) ───────────────────────────────────── */}
      <HowItWorks />

      {/* ── Employers ────────────────────────────────────────────────── */}
      <section>
        <Container className="py-16 sm:py-20">
          <div className="grid items-center gap-10 lg:grid-cols-2">
            <div>
              <Eyebrow>{t("employers.eyebrow")}</Eyebrow>
              <h2 className="text-foreground mt-3 text-3xl font-bold tracking-tight sm:text-4xl">
                {t("employers.title")}
              </h2>
              <p className="text-muted-foreground mt-4 text-pretty">
                {t("employers.body")}
              </p>
              <ul className="mt-6 space-y-3">
                {["area", "telegram", "pay", "free"].map((k) => (
                  <li key={k} className="flex items-start gap-3">
                    <Check className="text-primary mt-0.5 size-5 shrink-0" />
                    <span className="text-foreground text-sm">
                      {t(`employers.points.${k}`)}
                    </span>
                  </li>
                ))}
              </ul>
              <Link
                href={POST_HREF}
                className={cn(
                  buttonVariants({ variant: "primary", size: "md" }),
                  "mt-8 gap-2",
                )}
              >
                {t("employers.cta")}
                <ArrowRight className="size-4" />
              </Link>
            </div>

            {/* Branded "new application" mock */}
            <div className="border-border bg-card mx-auto w-full max-w-sm rounded-2xl border p-5 shadow-sm">
              <div className="mb-4 flex items-center gap-3">
                <span className="bg-primary text-primary-foreground flex size-10 items-center justify-center rounded-xl font-bold">
                  <Building2 className="size-5" />
                </span>
                <div className="min-w-0">
                  <p className="text-foreground truncate font-semibold">
                    {t("employers.card.store")}
                  </p>
                  <p className="text-muted-foreground truncate text-xs">
                    {t("employers.card.district")}
                  </p>
                </div>
                <span className="bg-primary/15 text-foreground ml-auto rounded-full px-2 py-0.5 text-xs font-semibold">
                  Business
                </span>
              </div>
              <p className="text-muted-foreground mb-2 text-xs font-semibold tracking-wide uppercase">
                {t("employers.card.appsTitle")}
              </p>
              <ul className="space-y-2">
                {[
                  {
                    name: t("employers.card.name1"),
                    phone: "+998 90 ••• 07",
                    ago: "2′",
                    fresh: true,
                  },
                  {
                    name: t("employers.card.name2"),
                    phone: "+998 93 ••• 44",
                    ago: "14′",
                    fresh: false,
                  },
                ].map((a) => (
                  <li
                    key={a.name}
                    className="border-border bg-background flex items-center gap-3 rounded-xl border p-3"
                  >
                    <span className="bg-muted text-foreground flex size-9 items-center justify-center rounded-full font-semibold">
                      {a.name.slice(0, 1)}
                    </span>
                    <div className="min-w-0">
                      <p className="text-foreground text-sm font-semibold">
                        {a.name}
                      </p>
                      <p className="text-muted-foreground font-mono text-xs">
                        {a.phone} · {a.ago}
                      </p>
                    </div>
                    {a.fresh ? (
                      <span className="bg-primary ml-auto size-2 rounded-full" />
                    ) : null}
                  </li>
                ))}
              </ul>
              <p className="text-muted-foreground mt-3 flex items-center gap-1.5 text-xs">
                <Send className="size-3.5" />
                {t("employers.card.badge")} · Telegram
              </p>
            </div>
          </div>
        </Container>
      </section>

      {/* ── Reputation ("flowers and flies") ─────────────────────────── */}
      <section
        id="reputation"
        className="border-border bg-muted/30 scroll-mt-16 border-y"
      >
        <Container className="py-16 sm:py-20">
          <SectionHead
            eyebrow={t("reputation.eyebrow")}
            title={t("reputation.title")}
            body={t("reputation.body")}
          />
          <div className="mt-10 grid gap-8 lg:grid-cols-2">
            <ol className="space-y-4">
              {["s1", "s2", "s3"].map((s, i) => (
                <li key={s} className="flex items-start gap-4">
                  <span className="border-primary/40 text-foreground flex size-9 shrink-0 items-center justify-center rounded-full border font-mono text-sm font-bold">
                    0{i + 1}
                  </span>
                  <p className="text-foreground pt-1 text-sm">
                    {t(`reputation.steps.${s}`)}
                  </p>
                </li>
              ))}
              <li className="flex flex-wrap gap-2 pt-2">
                {["verified", "badge", "notForSale", "reply"].map((c) => (
                  <span
                    key={c}
                    className="border-border bg-card text-muted-foreground rounded-full border px-3 py-1 text-xs font-medium"
                  >
                    {t(`reputation.chips.${c}`)}
                  </span>
                ))}
              </li>
              <li className="text-muted-foreground pt-1 text-xs">
                {t("reputation.note")}
              </li>
            </ol>

            <div className="space-y-3">
              <RatingCard
                name={t("reputation.good.name")}
                caption={t("reputation.good.caption")}
                score="9,2"
                marks="🌸🌸🌸🐝🐝"
                good
              />
              <RatingCard
                name={t("reputation.bad.name")}
                caption={t("reputation.bad.caption")}
                score="3,1"
                marks="🦟🦟🦟"
              />
              <p className="text-muted-foreground text-center text-xs">
                {t("reputation.footnote")}
              </p>
            </div>
          </div>
        </Container>
      </section>

      {/* ── Pricing ──────────────────────────────────────────────────── */}
      <section id="pricing" className="scroll-mt-16">
        <Container className="py-16 sm:py-20">
          <SectionHead
            eyebrow={t("pricing.eyebrow")}
            title={t("pricing.title")}
          />
          <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <PriceCard
              name={t("pricing.free.name")}
              price={t("pricing.free.price")}
              unit={t("pricing.free.unit")}
              features={[t("pricing.free.f1"), t("pricing.free.f2")]}
            />
            <PriceCard
              name={t("pricing.standard.name")}
              price={t("pricing.standard.price")}
              unit={t("pricing.standard.unit")}
              features={[t("pricing.standard.f1"), t("pricing.standard.f2")]}
            />
            <PriceCard
              name={t("pricing.brand.name")}
              price={t("pricing.brand.price")}
              unit={t("pricing.brand.unit")}
              tag={t("pricing.brand.tag")}
              features={[t("pricing.brand.f1"), t("pricing.brand.f2")]}
              featured
            />
            <PriceCard
              name={t("pricing.premium.name")}
              price={t("pricing.premium.price")}
              unit={t("pricing.premium.unit")}
              features={[
                t("pricing.premium.f1"),
                t("pricing.premium.f2"),
                t("pricing.premium.f3"),
              ]}
            />
          </div>
          <div className="mt-6 flex flex-col items-center gap-1 text-center">
            <p className="text-foreground text-sm font-medium">
              {t("pricing.note")}
            </p>
            <p className="text-muted-foreground text-xs">
              {t("pricing.footnote")}
            </p>
          </div>
        </Container>
      </section>

      {/* ── Comparison ───────────────────────────────────────────────── */}
      <section className="border-border bg-muted/30 border-y">
        <Container className="py-16 sm:py-20">
          <SectionHead
            eyebrow={t("comparison.eyebrow")}
            title={t("comparison.title")}
          />
          <div className="mt-10 overflow-x-auto">
            <table className="w-full min-w-[36rem] border-separate border-spacing-0 text-sm">
              <thead>
                <tr>
                  <th className="p-3" />
                  {(["us", "hh", "olx", "tg"] as const).map((c) => (
                    <th
                      key={c}
                      className={cn(
                        "p-3 text-center font-bold",
                        c === "us"
                          ? "text-foreground bg-primary/15 rounded-t-xl"
                          : "text-muted-foreground",
                      )}
                    >
                      {t(`comparison.cols.${c}`)}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {(
                  [
                    ["map", "label", "no", "no", "no"],
                    ["near", "yes", "no", "no", "no"],
                    ["noResume", "yes", "no", "no", "partial"],
                    ["price", "yes", "no", "no", "no"],
                    ["reputation", "yes", "no", "no", "no"],
                  ] as const
                ).map(([row, ...cells], ri, arr) => (
                  <tr key={row}>
                    <td className="text-foreground p-3 font-medium">
                      {t(`comparison.rows.${row}`)}
                    </td>
                    {cells.map((cell, ci) => (
                      <td
                        key={ci}
                        className={cn(
                          "p-3 text-center",
                          ci === 0 && "bg-primary/15",
                          ci === 0 && ri === arr.length - 1 && "rounded-b-xl",
                        )}
                      >
                        <CompCell
                          kind={cell}
                          mapCell={t("comparison.mapCell")}
                          partial={t("comparison.partial")}
                        />
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Container>
      </section>

      {/* ── Economics ────────────────────────────────────────────────── */}
      <section>
        <Container className="py-16 sm:py-20">
          <SectionHead
            eyebrow={t("economics.eyebrow")}
            title={t("economics.title")}
            body={t("economics.body")}
          />
          <div className="mt-10 grid gap-8 lg:grid-cols-2">
            {/* Unit-economics formula */}
            <div className="border-border bg-card flex flex-col gap-4 rounded-2xl border p-6">
              <div className="flex flex-wrap items-center justify-center gap-x-4 gap-y-3 text-center">
                <Figure
                  value={t("economics.payers")}
                  label={t("economics.payersLabel")}
                />
                <span className="text-muted-foreground text-2xl font-bold">
                  ×
                </span>
                <Figure
                  value={t("economics.check")}
                  label={t("economics.checkLabel")}
                />
                <span className="text-muted-foreground text-2xl font-bold">
                  ≈
                </span>
                <Figure
                  value={t("economics.total")}
                  label={t("economics.totalLabel")}
                  accent
                />
              </div>
              <p className="text-muted-foreground border-border mt-2 border-t pt-4 text-center text-sm">
                {t("economics.totalNote")}
              </p>
              <ul className="mt-2 space-y-2">
                {["conversion", "cac", "main"].map((m) => (
                  <li
                    key={m}
                    className="text-foreground flex items-center gap-2 text-sm"
                  >
                    <Sparkles className="text-primary size-4 shrink-0" />
                    {t(`economics.metrics.${m}`)}
                  </li>
                ))}
              </ul>
            </div>

            {/* Launch budget */}
            <div className="border-border bg-card rounded-2xl border p-6">
              <div className="mb-5 flex items-baseline justify-between">
                <h3 className="text-foreground font-bold">
                  {t("economics.budgetTitle")}
                </h3>
                <div className="text-right">
                  <p className="text-foreground font-mono text-xl font-bold">
                    {t("economics.budgetTotal")}
                  </p>
                  <p className="text-muted-foreground text-xs">
                    {t("economics.budgetNote")}
                  </p>
                </div>
              </div>
              <ul className="space-y-3">
                {(
                  [
                    ["marketing", 1500],
                    ["base", 600],
                    ["ai", 500],
                    ["infra", 300],
                    ["legal", 300],
                    ["design", 200],
                    ["reserve", 1600],
                  ] as const
                ).map(([k, n]) => (
                  <li key={k}>
                    <div className="mb-1 flex items-baseline justify-between gap-3 text-sm">
                      <span className="text-foreground">
                        {t(`economics.budget.${k}.label`)}
                      </span>
                      <span className="text-muted-foreground font-mono">
                        {t(`economics.budget.${k}.value`)}
                      </span>
                    </div>
                    <div className="bg-muted h-2 overflow-hidden rounded-full">
                      <div
                        className="bg-primary h-full rounded-full"
                        style={{ width: `${(n / 1600) * 100}%` }}
                      />
                    </div>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </Container>
      </section>

      {/* ── Roadmap ──────────────────────────────────────────────────── */}
      <section className="border-border bg-muted/30 border-y">
        <Container className="py-16 sm:py-20">
          <SectionHead
            eyebrow={t("roadmap.eyebrow")}
            title={t("roadmap.title")}
          />
          <ol className="border-border mt-10 space-y-8 border-l pl-6 sm:pl-8">
            {(["m12", "m3", "m46", "m79", "m1012"] as const).map((m, i) => (
              <li key={m} className="relative">
                <span
                  className={cn(
                    "absolute top-1.5 flex size-3 rounded-full ring-4",
                    "ring-background -left-[calc(1.5rem+6px)] sm:-left-[calc(2rem+6px)]",
                    i === 0 ? "bg-primary" : "bg-muted-foreground/40",
                  )}
                />
                <div className="flex flex-wrap items-center gap-2">
                  <span className="text-muted-foreground font-mono text-xs font-semibold tracking-wide">
                    {t(`roadmap.items.${m}.period`)}
                  </span>
                  {i === 0 ? (
                    <span className="bg-primary text-primary-foreground rounded-full px-2 py-0.5 text-[10px] font-bold tracking-wide uppercase">
                      {t("roadmap.hereLabel")}
                    </span>
                  ) : null}
                </div>
                <h3 className="text-foreground mt-1 text-lg font-bold">
                  {t(`roadmap.items.${m}.title`)}
                </h3>
                <p className="text-muted-foreground text-sm">
                  {t(`roadmap.items.${m}.body`)}
                </p>
              </li>
            ))}
          </ol>
        </Container>
      </section>

      {/* ── Partners ─────────────────────────────────────────────────── */}
      <section>
        <Container className="py-16 sm:py-20">
          <SectionHead
            eyebrow={t("partners.eyebrow")}
            title={t("partners.title")}
          />
          <div className="mt-10 grid gap-4 md:grid-cols-2">
            {(["telegram", "business"] as const).map((p) => (
              <div
                key={p}
                className="border-border bg-card hover:border-primary/40 rounded-2xl border p-6 transition-colors"
              >
                <span className="text-primary font-mono text-xs font-semibold tracking-wide uppercase">
                  {t(`partners.${p}.tag`)}
                </span>
                <h3 className="text-foreground mt-3 text-lg font-bold">
                  {t(`partners.${p}.title`)}
                </h3>
                <p className="text-muted-foreground mt-2 text-sm">
                  {t(`partners.${p}.body`)}
                </p>
              </div>
            ))}
          </div>
        </Container>
      </section>

      {/* ── Contact (closing volt band) ──────────────────────────────── */}
      <section className="bg-primary text-primary-foreground">
        <Container className="py-16 text-center sm:py-20">
          <BadgeCheck className="mx-auto size-8" />
          <h2 className="mt-4 text-3xl font-bold tracking-tight text-balance sm:text-4xl">
            {t("contact.title")}
          </h2>
          <p className="text-primary-foreground/80 mx-auto mt-4 max-w-xl text-pretty">
            {t("contact.body")}
          </p>
          <div className="mt-8 flex flex-col justify-center gap-3 sm:flex-row">
            <Link
              href={POST_HREF}
              className="bg-foreground text-background inline-flex h-12 items-center justify-center gap-2 rounded-full px-8 font-semibold transition-opacity hover:opacity-90"
            >
              {t("contact.ctaPost")}
              <ArrowRight className="size-4" />
            </Link>
            <a
              href={WRITE_HREF}
              className="border-primary-foreground/30 hover:bg-primary-foreground/10 inline-flex h-12 items-center justify-center gap-2 rounded-full border px-8 font-semibold transition-colors"
            >
              <Send className="size-4" />
              {t("contact.ctaWrite")}
            </a>
          </div>
          <p className="text-primary-foreground/70 mt-10 font-mono text-xs tracking-wide">
            yolla.uz · {COORDS}
          </p>
          <p className="text-primary-foreground/70 mt-1 text-xs">
            © 2026 · {t("contact.author")}
          </p>
        </Container>
      </section>
    </>
  );
}

/* ── Local presentational helpers (server components) ───────────────── */

function PriceCard({
  name,
  price,
  unit,
  features,
  tag,
  featured,
}: {
  name: string;
  price: string;
  unit: string;
  features: string[];
  tag?: string;
  featured?: boolean;
}) {
  return (
    <div
      className={cn(
        "flex flex-col rounded-2xl border p-6",
        featured
          ? "border-primary bg-card ring-primary/20 ring-2"
          : "border-border bg-card",
      )}
    >
      <div className="flex items-center justify-between">
        <h3 className="text-foreground font-bold">{name}</h3>
        {tag ? (
          <span className="bg-primary text-primary-foreground rounded-full px-2 py-0.5 text-[10px] font-bold tracking-wide uppercase">
            {tag}
          </span>
        ) : null}
      </div>
      <p className="mt-3 flex items-baseline gap-1">
        <span className="text-foreground font-mono text-2xl font-bold">
          {price}
        </span>
      </p>
      <p className="text-muted-foreground text-xs">{unit}</p>
      <ul className="mt-4 space-y-2">
        {features.map((f) => (
          <li
            key={f}
            className="text-foreground flex items-start gap-2 text-sm"
          >
            <Check className="text-primary mt-0.5 size-4 shrink-0" />
            {f}
          </li>
        ))}
      </ul>
    </div>
  );
}

function Figure({
  value,
  label,
  accent,
}: {
  value: string;
  label: string;
  accent?: boolean;
}) {
  return (
    <div>
      <p
        className={cn(
          "font-mono text-2xl font-bold sm:text-3xl",
          accent ? "text-primary" : "text-foreground",
        )}
      >
        {value}
      </p>
      <p className="text-muted-foreground text-xs">{label}</p>
    </div>
  );
}

function CompCell({
  kind,
  mapCell,
  partial,
}: {
  kind: "yes" | "no" | "label" | "partial";
  mapCell: string;
  partial: string;
}) {
  if (kind === "yes") {
    return <Check className="text-primary mx-auto size-5" aria-label="✓" />;
  }
  if (kind === "no") {
    return <span className="text-muted-foreground/50">—</span>;
  }
  const text = kind === "label" ? mapCell : partial;
  return <span className="text-foreground text-xs font-semibold">{text}</span>;
}
