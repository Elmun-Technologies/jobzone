import { ArrowUpRight, Send, Sparkles, Users } from "lucide-react";
import { getTranslations } from "next-intl/server";

import { FaqSection } from "@/components/seo/faq-section";
import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { getMarketplaceStats } from "@/lib/data/regions";
import { getPublicTelegramChannels } from "@/lib/data/telegram-channels";
import { groupNumber } from "@/lib/format";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

/**
 * What a guest or a job seeker sees at /employer: the case for hiring here.
 *
 * Until now the employer half of the marketplace had no front door — the
 * audience toggle dropped you straight into a blank post-a-vacancy form, which
 * asks for work before it has said what you get. Everything claimed on this
 * page is something the platform actually does, and every number is read from
 * the live feed rather than written into the copy.
 */
export async function EmployerLanding() {
  const t = await getTranslations("employerLanding");
  const tfaq = await getTranslations("employerFaq");

  const [stats, channels] = await Promise.all([
    getMarketplaceStats(),
    getPublicTelegramChannels(),
  ]);

  const faqItems = Array.from({ length: 5 }, (_, i) => ({
    question: tfaq(`q${i + 1}`),
    answer: tfaq(`a${i + 1}`),
  }));

  // The three ways this platform actually gets a vacancy filled. Numbered like
  // a method list because that is what an employer is choosing between.
  const methods = [
    {
      n: "01",
      Icon: Send,
      title: t("m1Title"),
      body: t("m1Body"),
      href: "/employer/jobs/new",
      cta: t("postFree"),
    },
    {
      n: "02",
      Icon: Users,
      title: t("m2Title"),
      body: t("m2Body"),
      href: "/employer/jobs/new",
      cta: t("m2Cta"),
    },
    {
      n: "03",
      Icon: Sparkles,
      title: t("m3Title"),
      body: t("m3Body"),
      href: "/pricing",
      cta: t("m3Cta"),
    },
  ];

  const figures = [
    { value: stats.openJobs, label: t("statJobs") },
    { value: stats.hiringCompanies, label: t("statCompanies") },
    { value: stats.activeRegions, label: t("statRegions") },
  ].filter((f) => f.value > 0);

  return (
    <>
      <Container className="py-10 sm:py-16">
        <div className="mx-auto max-w-3xl text-center">
          <h1 className="text-foreground text-4xl font-bold tracking-tight text-balance sm:text-5xl">
            {t("heroLead")}{" "}
            <span className="text-primary">{t("heroAccent")}</span>{" "}
            {t("heroTail")}
          </h1>
          <p className="text-muted-foreground mt-4 text-lg text-pretty">
            {t("heroSub")}
          </p>
          <div className="mt-7 flex flex-wrap justify-center gap-3">
            <Link
              href="/employer/jobs/new"
              className={cn(buttonVariants({ variant: "primary", size: "lg" }))}
            >
              {t("postFree")}
            </Link>
            <Link
              href="/pricing"
              className={cn(buttonVariants({ variant: "outline", size: "lg" }))}
            >
              {t("seePricing")}
            </Link>
          </div>
        </div>

        {/* Proof, not adjectives: the live feed's own numbers. Hidden entirely
            on a fresh install rather than showing a row of zeroes. */}
        {figures.length > 0 ? (
          <dl className="mt-12 grid grid-cols-1 gap-3 sm:grid-cols-3">
            {figures.map((f) => (
              <div
                key={f.label}
                className="border-border bg-card rounded-2xl border p-6 text-center"
              >
                <dt className="text-muted-foreground order-2 text-sm">
                  {f.label}
                </dt>
                <dd className="text-foreground font-mono text-3xl font-bold">
                  {groupNumber(f.value)}
                </dd>
              </div>
            ))}
          </dl>
        ) : null}
      </Container>

      <Container className="pb-4">
        <h2 className="text-foreground text-2xl font-bold tracking-tight sm:text-3xl">
          {t("methodsTitle")}
        </h2>
        <ul className="mt-6 grid grid-cols-1 gap-4 lg:grid-cols-3">
          {methods.map((m) => (
            <li key={m.n}>
              <div className="border-border bg-card flex h-full flex-col rounded-2xl border p-6">
                <div className="flex items-center gap-3">
                  <span className="bg-foreground text-background flex size-9 items-center justify-center rounded-full font-mono text-xs font-bold">
                    {m.n}
                  </span>
                  <m.Icon className="text-primary size-5" />
                </div>
                <h3 className="text-foreground mt-4 text-lg font-bold text-balance">
                  {m.title}
                </h3>
                <p className="text-muted-foreground mt-2 text-sm text-pretty">
                  {m.body}
                </p>
                <Link
                  href={m.href}
                  className="text-primary mt-auto pt-5 text-sm font-semibold hover:underline"
                >
                  {m.cta} →
                </Link>
              </div>
            </li>
          ))}
        </ul>
      </Container>

      {/* Distribution, shown rather than claimed. Real rows from the 0058
          channel map — no channel, no section. */}
      {channels.length > 0 ? (
        <Container className="py-14">
          <span className="text-primary font-mono text-xs font-semibold tracking-wide uppercase">
            {t("channelsKicker")}
          </span>
          <h2 className="text-foreground mt-2 text-2xl font-bold tracking-tight text-balance sm:text-3xl">
            {t("channelsTitle")}
          </h2>
          <p className="text-muted-foreground mt-2 max-w-2xl text-pretty">
            {t("channelsBody")}
          </p>
          <ul className="mt-6 grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {channels.map((c) => {
              const inner = (
                <>
                  <div className="flex items-start justify-between gap-3">
                    <span className="bg-accent text-accent-foreground flex size-10 shrink-0 items-center justify-center rounded-xl">
                      <Send className="size-5" />
                    </span>
                    {c.url ? (
                      <ArrowUpRight className="text-muted-foreground size-4 shrink-0" />
                    ) : null}
                  </div>
                  <p className="text-foreground mt-3 leading-snug font-semibold">
                    {c.title}
                  </p>
                  {c.handle ? (
                    <p className="text-muted-foreground font-mono text-sm">
                      {c.handle}
                    </p>
                  ) : null}
                  <p className="text-muted-foreground mt-2 text-sm">
                    {[c.categoryName, c.region ?? t("channelAllRegions")]
                      .filter(Boolean)
                      .join(" · ")}
                  </p>
                </>
              );
              const className =
                "border-border bg-card block h-full rounded-2xl border p-5 transition-colors";
              return (
                <li key={c.id}>
                  {c.url ? (
                    <a
                      href={c.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className={cn(className, "hover:border-primary/40")}
                    >
                      {inner}
                    </a>
                  ) : (
                    <div className={className}>{inner}</div>
                  )}
                </li>
              );
            })}
          </ul>
        </Container>
      ) : null}

      <FaqSection heading={tfaq("heading")} items={faqItems} />

      <Container className="pb-16">
        <div className="border-border bg-card flex flex-col items-center gap-4 rounded-3xl border p-8 text-center sm:p-12">
          <h2 className="text-foreground text-2xl font-bold text-balance sm:text-3xl">
            {t("ctaTitle")}
          </h2>
          <p className="text-muted-foreground max-w-xl text-pretty">
            {t("ctaBody")}
          </p>
          <Link
            href="/employer/jobs/new"
            className={cn(buttonVariants({ variant: "primary", size: "lg" }))}
          >
            {t("postFree")}
          </Link>
        </div>
      </Container>
    </>
  );
}
