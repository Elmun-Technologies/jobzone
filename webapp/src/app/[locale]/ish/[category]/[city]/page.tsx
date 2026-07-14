import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { JobCard } from "@/components/jobs/job-card";
import { JsonLd } from "@/components/seo/json-ld";
import { Container } from "@/components/ui/container";
import { getBookmarkedJobIds } from "@/lib/data/bookmarks";
import { getCategoryBySlug } from "@/lib/data/categories";
import { getCities, getJobCount, getOpenJobs } from "@/lib/data/jobs";
import { Link } from "@/i18n/navigation";
import { groupNumber } from "@/lib/format";
import {
  breadcrumbJsonLd,
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

  return (
    <>
      <JsonLd
        data={breadcrumbJsonLd([
          { name: t("breadcrumbHome"), url: `${localePath}` },
          { name: t("breadcrumbJobs"), url: `${localePath}/jobs` },
          { name: cat.name, url: `${localePath}/ish/${category}` },
          {
            name: cityName,
            url: `${localePath}/ish/${category}/${city}`,
          },
        ])}
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
        <p className="text-muted-foreground mt-2 text-sm">
          {t("resultsCount", { count: groupNumber(count) })}
        </p>

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
    </>
  );
}
