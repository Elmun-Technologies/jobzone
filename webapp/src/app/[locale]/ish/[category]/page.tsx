import type { Metadata } from "next";
import { notFound, redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { JobCard } from "@/components/jobs/job-card";
import { FaqSection } from "@/components/seo/faq-section";
import { JsonLd } from "@/components/seo/json-ld";
import { QuickFacts } from "@/components/seo/quick-facts";
import { Container } from "@/components/ui/container";
import {
  getCategories,
  getCategoryByHistoricalSlug,
  getCategoryBySlug,
} from "@/lib/data/categories";
import { getCities, getPublicJobCount, getPublicJobs } from "@/lib/data/jobs";
import { Link } from "@/i18n/navigation";
import { groupNumber, salaryRangeUzsText } from "@/lib/format";
import { latestPostedAt, uzsSalaryRange } from "@/lib/geo-stats";
import {
  breadcrumbJsonLd,
  collectionPageJsonLd,
  jobsItemListJsonLd,
  localeAlternates,
  siteUrl,
} from "@/lib/seo";
import { slugify } from "@/lib/slug";

// This page reads only cached public data — `getPublicJobs`/`getPublicJobCount`
// go through the anon client, carry a short window and are flushed by the
// "jobs" tag on publish/close/edit — and nothing per-visitor. That is what
// lets it be prerendered and served from the CDN, while a new posting still
// appears the moment it is published, which is what invariant #3 asks for.
// The one thing it gives up is the seeker's personal archive: a vacancy
// someone dismissed still shows here, exactly as it already does on the region
// landings. A shared page shows the market, not one visitor's edit of it.
//
// Cap: enough to satisfy the ItemList schema without blowing up TTFB when a
// hot category has thousands of postings. Deeper browsing goes through /jobs.
const LANDING_LIMIT = 30;

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

/**
 * Prebuild every trade we have. Categories are a curated set of a couple of
 * dozen, so this is cheap; a category added later is rendered on first request
 * and cached from then on (`dynamicParams` defaults to true). A build without
 * backend credentials gets an empty list and the same on-demand path.
 */
export async function generateStaticParams() {
  const categories = await getCategories();
  return categories.map((c) => ({ category: c.slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string; category: string }>;
}): Promise<Metadata> {
  const { locale, category } = await params;
  const cat = await getCategoryBySlug(category);
  if (!cat) return { title: "404" };
  const t = await getTranslations({ locale, namespace: "landingPage" });
  const title = t("metaTitleCategory", { category: cat.name });
  const description = t("metaDescriptionCategory", { category: cat.name });
  return {
    title,
    description,
    alternates: localeAlternates(locale, `ish/${category}`),
    openGraph: { title, description, type: "website" },
  };
}

export default async function CategoryLandingPage({
  params,
}: {
  params: Promise<{ locale: string; category: string }>;
}) {
  const { locale, category } = await params;
  setRequestLocale(locale);
  const cat = await getCategoryBySlug(category);
  if (!cat) {
    // Renamed since the crawler last saw it? Look up the retired slug and
    // 301 forward — Google keeps the historical PageRank on the new URL.
    // Only reached on real miss (the current-slug lookup already failed),
    // so no extra query for the happy path.
    const historical = await getCategoryByHistoricalSlug(category);
    if (historical) redirect(`/${locale}/ish/${historical.slug}`);
    notFound();
  }

  const t = await getTranslations("landingPage");
  const tfaq = await getTranslations("landingFaq");
  // Category-scoped FAQ (7 items). The {category} placeholder is filled
  // on the server so the visible text and the FAQPage JSON-LD say the
  // same thing — Google's rich-results policy requires the two to match.
  const faqItems = Array.from({ length: 7 }, (_, i) => ({
    question: tfaq(`q${i + 1}`, { category: cat.name }),
    answer: tfaq(`a${i + 1}`, { category: cat.name }),
  }));
  const faqHeading = tfaq("heading", { category: cat.name });

  const [jobs, count, cities] = await Promise.all([
    getPublicJobs({ category: cat.name, limit: LANDING_LIMIT }),
    getPublicJobCount({ category: cat.name }),
    // Every city already has at least one job on the platform (getCities()
    // is derived from postings), so the internal-links row on this landing
    // shows only cities that actually resolve to jobs somewhere on Yolla —
    // filtering to "cities with this category" would require N extra head
    // counts and doesn't move the SEO needle.
    getCities(),
  ]);

  const base = siteUrl();
  const localePath = `${base}/${locale}`;

  const canonicalUrl = `${localePath}/ish/${category}`;

  return (
    <>
      <JsonLd
        data={breadcrumbJsonLd([
          { name: t("breadcrumbHome"), url: `${localePath}` },
          { name: t("breadcrumbJobs"), url: `${localePath}/jobs` },
          { name: cat.name, url: canonicalUrl },
        ])}
      />
      <JsonLd
        data={collectionPageJsonLd({
          url: canonicalUrl,
          name: t("titleCategory", { category: cat.name }),
          description: t("introCategory", { category: cat.name }),
          categoryName: cat.name,
          inLanguage: locale,
          itemCount: count,
          dateModified: latestPostedAt(jobs) ?? undefined,
        })}
      />
      {jobs.length > 0 ? (
        <JsonLd data={jobsItemListJsonLd(jobs, locale)} />
      ) : null}

      <Container className="py-10 sm:py-14">
        {/* Breadcrumb strip (visual). Mirrors the JSON-LD above; text is
            short so it doesn't compete with the H1 for attention. */}
        <nav
          aria-label="breadcrumb"
          className="text-muted-foreground mb-4 flex flex-wrap items-center gap-1 text-sm"
        >
          <Link href="/" className="hover:text-foreground">
            {t("breadcrumbHome")}
          </Link>
          <span aria-hidden>/</span>
          <Link href="/jobs" className="hover:text-foreground">
            {t("breadcrumbJobs")}
          </Link>
          <span aria-hidden>/</span>
          <span className="text-foreground font-medium">{cat.name}</span>
        </nav>

        <h1 className="text-foreground text-3xl font-bold tracking-tight text-balance sm:text-4xl">
          {t("titleCategory", { category: cat.name })}
        </h1>
        <p className="text-muted-foreground mt-3 max-w-2xl text-lg text-pretty">
          {t("introCategory", { category: cat.name })}
        </p>

        {/* GEO quick-facts strip — concrete numbers an LLM will quote
            back verbatim, and a human skims in one glance. Salary range
            is a 25th–75th percentile band across UZS-quoted jobs. */}
        {(() => {
          const range = uzsSalaryRange(jobs);
          const updated = latestPostedAt(jobs);
          return (
            <QuickFacts
              label={t("quickFactsLabel")}
              items={[
                {
                  label: t("factVacancies"),
                  value: groupNumber(count),
                },
                {
                  label: t("factSalaryRange"),
                  value: range
                    ? salaryRangeUzsText(range.low, range.high)
                    : t("factSalaryNa"),
                },
                {
                  label: t("factCities"),
                  value:
                    cities.length > 0
                      ? String(cities.length)
                      : t("factCitiesNa"),
                },
              ]}
              updatedIso={updated}
              updatedLabel={t("factUpdated")}
            />
          );
        })()}

        {jobs.length > 0 ? (
          <ul className="mt-8 grid grid-cols-1 gap-3 md:grid-cols-2 lg:grid-cols-3">
            {jobs.map((job) => (
              <li key={job.id}>
                <JobCard job={job} />
              </li>
            ))}
          </ul>
        ) : (
          <p className="border-border bg-muted/30 mt-8 rounded-xl border p-6 text-center text-sm">
            {t("empty")}
          </p>
        )}

        {/* Internal linking: every city gets a link to /ish/[category]/[city].
            This is the mesh Google crawls to discover the deep landing set. */}
        {cities.length > 0 ? (
          <section className="mt-14">
            <h2 className="text-foreground text-xl font-bold">{t("byCity")}</h2>
            <ul className="mt-4 flex flex-wrap gap-2">
              {cities.map((c) => (
                <li key={c}>
                  <Link
                    href={`/ish/${category}/${slugify(c)}`}
                    className="border-border bg-card hover:border-primary/40 inline-flex items-center rounded-full border px-3 py-1.5 text-sm font-medium transition-colors"
                  >
                    {t("titleCategoryCity", { city: c, category: cat.name })}
                  </Link>
                </li>
              ))}
            </ul>
          </section>
        ) : null}

        <section className="mt-14 max-w-3xl">
          <h2 className="text-foreground text-xl font-bold">
            {t("seoBlockTitle", { category: cat.name })}
          </h2>
          <p className="text-muted-foreground mt-3 text-pretty">
            {t("seoBlockBody", { category: cat.name })}
          </p>
        </section>
      </Container>

      {/* Category-scoped FAQ — visible + FAQPage JSON-LD. Every answer
          mentions the category name so an LLM can quote the exact
          Q/A pair when a user asks about it. */}
      <FaqSection heading={faqHeading} items={faqItems} />
    </>
  );
}
