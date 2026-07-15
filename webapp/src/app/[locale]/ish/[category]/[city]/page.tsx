import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { JobCard } from "@/components/jobs/job-card";
import { FaqSection } from "@/components/seo/faq-section";
import { JsonLd } from "@/components/seo/json-ld";
import { QuickFacts } from "@/components/seo/quick-facts";
import { Container } from "@/components/ui/container";
import { getBookmarkedJobIds } from "@/lib/data/bookmarks";
import { getCategoryBySlug } from "@/lib/data/categories";
import { getCities, getJobCount, getOpenJobs } from "@/lib/data/jobs";
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

export const dynamic = "force-dynamic";
const LANDING_LIMIT = 30;

/** Resolve a city slug back to the canonical city string used in the jobs
 * table. Returns null when the slug matches nothing on the platform, so the
 * caller can 404 rather than showing an empty page. */
async function resolveCity(slug: string): Promise<string | null> {
  const cities = await getCities();
  return cities.find((c) => slugify(c) === slug) ?? null;
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string; category: string; city: string }>;
}): Promise<Metadata> {
  const { locale, category, city } = await params;
  const cat = await getCategoryBySlug(category);
  const cityName = await resolveCity(city);
  if (!cat || !cityName) return { title: "404" };
  const t = await getTranslations({ locale, namespace: "landingPage" });
  const title = t("metaTitleCategoryCity", {
    city: cityName,
    category: cat.name,
  });
  const description = t("metaDescriptionCategoryCity", {
    city: cityName,
    category: cat.name,
  });
  return {
    title,
    description,
    alternates: localeAlternates(locale, `ish/${category}/${city}`),
    openGraph: { title, description, type: "website" },
  };
}

export default async function CategoryCityLandingPage({
  params,
}: {
  params: Promise<{ locale: string; category: string; city: string }>;
}) {
  const { locale, category, city } = await params;
  setRequestLocale(locale);
  const cat = await getCategoryBySlug(category);
  const cityName = await resolveCity(city);
  if (!cat || !cityName) notFound();

  const t = await getTranslations("landingPage");
  const tfaq = await getTranslations("landingFaq");
  // City-scoped FAQ reuses the category FAQ but binds {category} to
  // the current category name. The city context is embedded in the
  // surrounding page copy (H1 / intro), which is what an LLM will
  // read alongside the FAQ answer.
  const faqItems = Array.from({ length: 7 }, (_, i) => ({
    question: tfaq(`q${i + 1}`, { category: cat.name }),
    answer: tfaq(`a${i + 1}`, { category: cat.name }),
  }));
  const faqHeading = tfaq("heading", { category: cat.name });

  const [jobs, count, cities, savedIds] = await Promise.all([
    getOpenJobs({
      category: cat.name,
      city: cityName,
      limit: LANDING_LIMIT,
    }),
    getJobCount({ category: cat.name, city: cityName }),
    getCities(),
    getBookmarkedJobIds(),
  ]);

  const base = siteUrl();
  const localePath = `${base}/${locale}`;
  const canonicalUrl = `${localePath}/ish/${category}/${city}`;

  return (
    <>
      <JsonLd
        data={breadcrumbJsonLd([
          { name: t("breadcrumbHome"), url: `${localePath}` },
          { name: t("breadcrumbJobs"), url: `${localePath}/jobs` },
          { name: cat.name, url: `${localePath}/ish/${category}` },
          { name: cityName, url: canonicalUrl },
        ])}
      />
      <JsonLd
        data={collectionPageJsonLd({
          url: canonicalUrl,
          name: t("titleCategoryCity", {
            city: cityName,
            category: cat.name,
          }),
          description: t("introCategoryCity", {
            city: cityName,
            category: cat.name,
          }),
          categoryName: cat.name,
          city: cityName,
          inLanguage: locale,
          itemCount: count,
          dateModified: latestPostedAt(jobs) ?? undefined,
        })}
      />
      {jobs.length > 0 ? (
        <JsonLd data={jobsItemListJsonLd(jobs, locale)} />
      ) : null}

      <Container className="py-10 sm:py-14">
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
          <Link
            href={`/ish/${category}`}
            className="hover:text-foreground"
          >
            {cat.name}
          </Link>
          <span aria-hidden>/</span>
          <span className="text-foreground font-medium">{cityName}</span>
        </nav>

        <h1 className="text-foreground text-3xl font-bold tracking-tight text-balance sm:text-4xl">
          {t("titleCategoryCity", { city: cityName, category: cat.name })}
        </h1>
        <p className="text-muted-foreground mt-3 max-w-2xl text-lg text-pretty">
          {t("introCategoryCity", {
            city: cityName,
            category: cat.name,
          })}
        </p>

        {/* GEO quick-facts strip — same shape as the category landing,
            but the "Cities" slot is dropped (the page IS one city). */}
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
                { label: t("factCities"), value: cityName },
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
                <JobCard job={job} saved={savedIds.has(job.id)} />
              </li>
            ))}
          </ul>
        ) : (
          <p className="border-border bg-muted/30 mt-8 rounded-xl border p-6 text-center text-sm">
            {t("empty")}
          </p>
        )}

        {cities.length > 1 ? (
          <section className="mt-14">
            <h2 className="text-foreground text-xl font-bold">
              {t("byCity")}
            </h2>
            <ul className="mt-4 flex flex-wrap gap-2">
              {cities
                .filter((c) => slugify(c) !== city)
                .map((c) => (
                  <li key={c}>
                    <Link
                      href={`/ish/${category}/${slugify(c)}`}
                      className="border-border bg-card hover:border-primary/40 inline-flex items-center rounded-full border px-3 py-1.5 text-sm font-medium transition-colors"
                    >
                      {t("titleCategoryCity", {
                        city: c,
                        category: cat.name,
                      })}
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

      <FaqSection heading={faqHeading} items={faqItems} />
    </>
  );
}
