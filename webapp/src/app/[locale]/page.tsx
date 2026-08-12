import { ChevronRight, MapPin, Search, TrendingUp } from "lucide-react";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { CompanyCard } from "@/components/companies/company-card";
import { EmployerCta } from "@/components/landing/employer-cta";
import { HeroMapBackdrop } from "@/components/landing/hero-map-backdrop";
import { HowItWorks } from "@/components/landing/how-it-works";
import { LandingMap } from "@/components/landing/landing-map";
import { pickLandingMapJobs } from "@/components/landing/landing-map-shared";
import { JobCard } from "@/components/jobs/job-card";
import { RoleToggle } from "@/components/layout/role-toggle";
import { FaqSection } from "@/components/seo/faq-section";
import { JsonLd } from "@/components/seo/json-ld";
import { AnimatedSearchInput } from "@/components/ui/animated-search-input";
import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { categoryEmoji } from "@/lib/categories-meta";
import { getCategoriesWithCounts } from "@/lib/data/categories";
import { getCompanies, getCompanyRatings } from "@/lib/data/companies";
import { getCities, getPublicJobCount, getPublicJobs } from "@/lib/data/jobs";
import { groupNumber } from "@/lib/format";
import { Link } from "@/i18n/navigation";
import { orgJsonLd, websiteJsonLd } from "@/lib/seo";
import { cn } from "@/lib/utils";

// Nothing here is read per visitor any more, so the home page is prerendered
// and served from the CDN — the single biggest thing standing between a
// first-time visitor and a painted page.
//
// The feed reads go through the cached public readers, which a publish, close
// or edit flushes via the "jobs" tag, so a new vacancy still shows up at once
// (invariant #3). The saved hearts fill in from the browser
// (SavedJobsProvider). What the page gives up is the seeker's personal
// archive: a vacancy someone dismissed still appears in the showcase here, as
// it already did on the region and category landings. The archive still
// governs where a seeker actually browses — /jobs and /explore.

/**
 * Rebuilt at most every five minutes, and immediately whenever an employer
 * publishes, closes, edits or boosts a vacancy (`revalidateTag("jobs")`).
 *
 * The tag flush is what makes invariant #3 hold — a new posting is visible at
 * once. This window is the safety net under it: publishing also happens where
 * no server action runs, from the `publish_due_jobs()` cron and the payment
 * webhook, and vacancies expire on a timestamp nobody flushes. Without a
 * window those changes would sit behind stale HTML indefinitely.
 */
export const revalidate = 300;

export default async function HomePage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("home");
  const tj = await getTranslations("jobs");
  const tm = await getTranslations("explore.map");
  const tfaq = await getTranslations("homeFaq");
  const tc = await getTranslations("common");
  const searchExamples = tc.raw("searchExamples") as string[];

  // Compact FAQ set (7 Q/A) — visible HTML + FAQPage JSON-LD via
  // FaqSection. Kept in the messages catalog so uz/ru/en can drift as
  // needed; the message-parity test blocks a locale skipping a key.
  const faqItems = Array.from({ length: 7 }, (_, i) => ({
    question: tfaq(`q${i + 1}`),
    answer: tfaq(`a${i + 1}`),
  }));

  const [recent, mapJobs, ratings, categories, total, cities, topCompanies] =
    await Promise.all([
      getPublicJobs({ limit: 6 }),
      // The landing showcase pins up to 8 jobs — fetch a small salaried set so
      // pins actually populate; the full pannable feed lives on /explore.
      getPublicJobs({ limit: 24 }),
      // Live company ratings for the pins' hover cards.
      getCompanyRatings(),
      getCategoriesWithCounts(),
      getPublicJobCount(),
      getCities(),
      getCompanies({ limit: 8 }),
    ]);

  // Popular-search shortcuts, reusing existing job-filter labels.
  const presets = [
    { label: tj("exp.entry"), href: "/jobs?experienceLevel=entry" },
    { label: tj("model.remote"), href: "/jobs?workingModel=remote" },
    { label: tj("type.part_time"), href: "/jobs?jobType=part_time" },
    { label: tj("type.full_time"), href: "/jobs?jobType=full_time" },
    { label: tj("type.internship"), href: "/jobs?jobType=internship" },
    { label: tj("type.rotational"), href: "/jobs?jobType=rotational" },
  ];

  return (
    <>
      {/* Organization + WebSite (with SearchAction) — enables the Sitelinks
          search box and cements the brand knowledge panel. Rendered once on
          the home page; the layout adds nothing global to keep this scoped. */}
      <JsonLd data={orgJsonLd()} />
      <JsonLd data={websiteJsonLd(locale)} />

      {/* Hero — a dark map-poster card (grid + floating salary pins) instead
          of a plain text block, so the brand's map-first identity reads
          immediately instead of only after scrolling to the real map below. */}
      <Container className="py-10 sm:py-14">
        {/* #171716, not the brand ink: this is the largest dark area on the
            site and it sits on white, so pure black made the page a
            maximum-contrast slab. The lift reads the same at a glance and is
            far easier to sit in front of. */}
        <div className="relative isolate overflow-hidden rounded-3xl bg-[#171716] px-5 py-16 sm:px-10 sm:py-24">
          <HeroMapBackdrop />
          <div className="relative z-10 mx-auto flex max-w-3xl flex-col items-center gap-5 text-center">
            {/* Seeker ⇄ employer, on phones only: the header hides this pill
                below `sm` (it doesn't fit next to the logo and the auth
                buttons), which left the entire employer side of the
                marketplace reachable only through the drawer. At the top of
                the hero it is the first thing a visitor sees, which is where
                the audience split belongs. */}
            <div className="sm:hidden">
              <RoleToggle tone="onDark" />
            </div>
            <span className="inline-flex items-center gap-2 rounded-full border border-white/15 bg-white/10 px-3 py-1 font-mono text-xs font-semibold tracking-wide text-white/80 uppercase backdrop-blur">
              <MapPin className="text-primary size-3.5" />
              {t("heroBadge")}
            </span>
            <h1 className="text-4xl font-bold tracking-tight text-balance text-white sm:text-6xl">
              {t("heroTitle")}
            </h1>
            <p className="text-lg text-pretty text-white/70">
              {t("heroSubtitle")}
            </p>
            {total > 0 ? (
              <p className="text-sm text-white/60">
                {t("jobCount", { count: groupNumber(total) })}
              </p>
            ) : null}

            <form
              action={`/${locale}/jobs`}
              className="flex w-full max-w-2xl flex-col gap-2 rounded-2xl bg-white/95 p-2 shadow-xl backdrop-blur sm:flex-row sm:items-center sm:rounded-full"
            >
              <div className="flex flex-1 items-center gap-2">
                <Search className="ml-2 size-5 shrink-0 text-neutral-500" />
                <AnimatedSearchInput
                  name="q"
                  examples={searchExamples}
                  ariaLabel={t("searchPlaceholder")}
                  className="h-10 w-full bg-transparent px-1 text-neutral-900 outline-none placeholder:text-neutral-500"
                />
              </div>
              <div className="flex items-center gap-2">
                {cities.length > 0 ? (
                  <select
                    name="city"
                    defaultValue=""
                    aria-label={t("allRegions")}
                    className="h-10 max-w-[10rem] rounded-full bg-neutral-100 px-3 text-sm text-neutral-900 outline-none sm:bg-transparent"
                  >
                    <option value="">{t("allRegions")}</option>
                    {cities.map((c) => (
                      <option key={c} value={c}>
                        {c}
                      </option>
                    ))}
                  </select>
                ) : null}
                <button
                  type="submit"
                  className={cn(
                    buttonVariants({ variant: "primary", size: "sm" }),
                    "shrink-0",
                  )}
                >
                  {t("searchCta")}
                </button>
              </div>
            </form>
          </div>
        </div>
      </Container>

      {/* Map — the centrepiece */}
      <section id="map" className="scroll-mt-16">
        <Container className="pb-16">
          <div className="mb-5 flex flex-wrap items-end justify-between gap-3">
            <div>
              <h2 className="text-foreground text-2xl font-bold tracking-tight sm:text-3xl">
                {t("mapTitle")}
              </h2>
              <p className="text-muted-foreground mt-1 text-sm">
                {t("mapLead")}
              </p>
            </div>
            <Link
              href="/explore"
              className={cn(buttonVariants({ variant: "outline", size: "sm" }))}
            >
              {t("exploreCta")}
            </Link>
          </div>
          {(() => {
            const pinned = pickLandingMapJobs(mapJobs);
            return (
              <LandingMap
                jobs={pinned}
                ratings={ratings}
                labels={{
                  chipNearMe: tm("nearMe"),
                  chipSalary: tm("salaryFrom"),
                  chipSchedule: tm("schedule22"),
                  results: tm("results", { count: pinned.length }),
                  nearMeCta: tm("nearMe"),
                  youAreHere: tm("youAreHere"),
                  pinHint: t("mapLead"),
                  cityLabel: (cities[0] ?? "Toshkent").toUpperCase(),
                  negotiable: tj("negotiable"),
                  zoomIn: t("map.zoomIn"),
                  zoomOut: t("map.zoomOut"),
                }}
              />
            );
          })()}
        </Container>
      </section>

      {/* How it works */}
      <HowItWorks />

      {/* Category grid — only categories that actually have open vacancies
          today. Rendering all 22 seed categories with "0 vakansiya" per
          card on Day 1 makes the marketplace look broken; hiding an empty
          category and re-appearing it once real jobs land is the right
          trade. */}
      {(() => {
        const activeCategories = categories.filter((c) => c.count > 0);
        return activeCategories.length > 0 ? (
          <Container className="py-16">
            <ul className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
              {activeCategories.map((c) => (
                <li key={c.id}>
                  <Link
                    // Deep-link into the SEO landing (/ish/[category]) instead
                    // of a faceted /jobs?category= URL — the landing has its
                    // own H1, canonical, and JSON-LD, and inbound internal
                    // links from the home page are how Google ranks it.
                    href={`/ish/${c.slug}`}
                    className="border-border bg-card hover:border-primary/40 flex h-full flex-col gap-2 rounded-xl border p-4 transition-all hover:shadow-sm"
                  >
                    <span className="text-3xl leading-none">
                      {categoryEmoji(c)}
                    </span>
                    <span className="text-foreground leading-snug font-semibold">
                      {c.name}
                    </span>
                    <span className="text-muted-foreground mt-auto text-sm">
                      {t("vacancyCount", { count: groupNumber(c.count) })}
                    </span>
                  </Link>
                </li>
              ))}
            </ul>
          </Container>
        ) : null;
      })()}

      {/* Popular searches */}
      <Container className="pb-16">
        <h2 className="text-foreground mb-4 text-xl font-bold">
          {t("popularSearches")}
        </h2>
        <ul className="grid grid-cols-2 gap-3 sm:grid-cols-3">
          {presets.map((p) => (
            <li key={p.href}>
              <Link
                href={p.href}
                className="border-border bg-card hover:border-primary/40 flex items-center justify-between gap-2 rounded-xl border p-4 transition-all hover:shadow-sm"
              >
                <span className="flex min-w-0 items-center gap-2">
                  <span className="bg-accent text-accent-foreground flex size-9 shrink-0 items-center justify-center rounded-full">
                    <TrendingUp className="size-4" />
                  </span>
                  <span className="text-foreground truncate font-medium">
                    {p.label}
                  </span>
                </span>
                <ChevronRight className="text-muted-foreground size-4 shrink-0" />
              </Link>
            </li>
          ))}
        </ul>
      </Container>

      {/* Recent jobs */}
      {recent.length > 0 ? (
        <Container className="pb-16">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="text-foreground text-xl font-bold">
              {t("recentJobs")}
            </h2>
            <Link
              href="/jobs"
              className="text-foreground text-sm font-semibold hover:underline"
            >
              {t("viewAll")}
            </Link>
          </div>
          <ul className="grid grid-cols-1 gap-3 md:grid-cols-2 lg:grid-cols-3">
            {recent.map((job) => (
              <li key={job.id}>
                <JobCard job={job} />
              </li>
            ))}
          </ul>
        </Container>
      ) : null}

      {/* Top companies */}
      {topCompanies.length > 0 ? (
        <Container className="pb-20">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="text-foreground text-xl font-bold">
              {t("topCompanies")}
            </h2>
            <Link
              href="/companies"
              className="text-foreground text-sm font-semibold hover:underline"
            >
              {t("viewAll")}
            </Link>
          </div>
          <ul className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
            {topCompanies.map((c) => (
              <li key={c.id}>
                <CompanyCard company={c} />
              </li>
            ))}
          </ul>
        </Container>
      ) : null}

      {/* Reputation teaser removed on launch: it rendered scripted
          example ratings ("Bahor kafesi 9,2" / "7-ombor 3,1"), which
          are demonstrably fake companies. As soon as real
          `worker_reviews` accumulate we can wire a live-rating widget
          here that reads the top-N and bottom-N from a view; keeping
          the placeholder version was a customer-trust risk. */}

      {/* FAQ — visible + FAQPage JSON-LD. GEO signal: LLMs (ChatGPT /
          Claude / Perplexity / Gemini) quote FAQ answers verbatim, and
          Google may render this as a rich result on the SERP. */}
      <FaqSection heading={tfaq("heading")} items={faqItems} />

      {/* Employer CTA */}
      <EmployerCta />
    </>
  );
}
