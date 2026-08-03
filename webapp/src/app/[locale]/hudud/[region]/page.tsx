import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { JobCard } from "@/components/jobs/job-card";
import { FaqSection } from "@/components/seo/faq-section";
import { JsonLd } from "@/components/seo/json-ld";
import { Container } from "@/components/ui/container";
import { categoryEmoji } from "@/lib/categories-meta";
import { getRegionJobs, getRegionSnapshot } from "@/lib/data/regions";
import { Link } from "@/i18n/navigation";
import { groupNumber } from "@/lib/format";
import { latestPostedAt } from "@/lib/geo-stats";
import {
  breadcrumbJsonLd,
  collectionPageJsonLd,
  jobsItemListJsonLd,
  localeAlternates,
  siteUrl,
} from "@/lib/seo";
import { slugify } from "@/lib/slug";
import { UZ_REGION_NAMES } from "@/lib/uz-districts";

/**
 * "All the work in this viloyat" — the long-tail page shape the local job
 * sites have and we did not: people search by place first ("Andijonda ish",
 * "работа в Фергане") and only then narrow by trade.
 *
 * Unlike the rest of the app this page is NOT force-dynamic. Nothing on it is
 * per-visitor except the saved-job hearts, and its data comes from the cached
 * public readers (see data/regions.ts), so it renders without a live Supabase
 * fan-out — which is what a crawler hitting fourteen of these back to back
 * needs, and what stops a cold serverless function from spending its budget on
 * round-trips before the first byte.
 */

const LANDING_LIMIT = 24;

/** Region name from a URL slug ("toshkent-shahri" → "Toshkent shahri"). */
function resolveRegion(slug: string): string | null {
  return UZ_REGION_NAMES.find((r) => slugify(r) === slug) ?? null;
}

// The fourteen regions are a fixed list, so every one of these pages is built
// once and served from the edge instead of rendered per request.
export function generateStaticParams() {
  return UZ_REGION_NAMES.map((r) => ({ region: slugify(r) }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string; region: string }>;
}): Promise<Metadata> {
  const { locale, region } = await params;
  const name = resolveRegion(region);
  if (!name) return { title: "404" };
  const t = await getTranslations({ locale, namespace: "regionPage" });
  const title = t("metaTitle", { region: name });
  const description = t("metaDescription", { region: name });
  return {
    title,
    description,
    alternates: localeAlternates(locale, `hudud/${region}`),
    openGraph: { title, description, type: "website" },
  };
}

export default async function RegionLandingPage({
  params,
}: {
  params: Promise<{ locale: string; region: string }>;
}) {
  const { locale, region } = await params;
  setRequestLocale(locale);
  const name = resolveRegion(region);
  if (!name) notFound();

  const t = await getTranslations("regionPage");
  const tl = await getTranslations("landingPage");
  const tfaq = await getTranslations("regionFaq");

  const [snapshot, jobs] = await Promise.all([
    getRegionSnapshot(name),
    getRegionJobs(name, LANDING_LIMIT),
  ]);

  const faqItems = Array.from({ length: 5 }, (_, i) => ({
    question: tfaq(`q${i + 1}`, { region: name }),
    answer: tfaq(`a${i + 1}`, { region: name }),
  }));

  const base = siteUrl();
  const localePath = `${base}/${locale}`;
  const canonicalUrl = `${localePath}/hudud/${region}`;

  return (
    <>
      <JsonLd
        data={breadcrumbJsonLd([
          { name: tl("breadcrumbHome"), url: localePath },
          { name: tl("breadcrumbJobs"), url: `${localePath}/jobs` },
          { name: name, url: canonicalUrl },
        ])}
      />
      <JsonLd
        data={collectionPageJsonLd({
          url: canonicalUrl,
          name: t("title", { region: name }),
          description: t("intro", { region: name }),
          categoryName: t("allCategories"),
          city: name,
          inLanguage: locale,
          itemCount: snapshot.total,
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
            {tl("breadcrumbHome")}
          </Link>
          <span aria-hidden>/</span>
          <Link href="/jobs" className="hover:text-foreground">
            {tl("breadcrumbJobs")}
          </Link>
          <span aria-hidden>/</span>
          <span className="text-foreground">{name}</span>
        </nav>

        <h1 className="text-foreground text-3xl font-bold tracking-tight text-balance sm:text-4xl">
          {t("title", { region: name })}
        </h1>
        <p className="text-muted-foreground mt-3 max-w-2xl text-pretty">
          {t("intro", { region: name })}
        </p>
        {snapshot.total > 0 ? (
          <p className="text-muted-foreground mt-2 font-mono text-sm">
            {tl("resultsCount", { count: groupNumber(snapshot.total) })}
          </p>
        ) : null}

        {/* Trade × region: the grid is the region page's whole job as an entry
            point — every card is a deeper long-tail URL that already exists
            (/ish/[category]/[city]) and had nothing linking to it. */}
        {snapshot.categories.length > 0 ? (
          <section className="mt-8">
            <h2 className="text-foreground mb-4 text-xl font-bold">
              {tl("byCategory")}
            </h2>
            <ul className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
              {snapshot.categories.map((c) => (
                <li key={c.slug}>
                  <Link
                    href={`/ish/${c.slug}/${slugify(name)}`}
                    className="border-border bg-card hover:border-primary/40 flex h-full flex-col gap-2 rounded-xl border p-4 transition-all hover:shadow-sm"
                  >
                    <span className="text-2xl leading-none">
                      {categoryEmoji({ slug: c.slug, name: c.name })}
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
          </section>
        ) : null}

        <section className="mt-10">
          <h2 className="text-foreground mb-4 text-xl font-bold">
            {t("latest", { region: name })}
          </h2>
          {jobs.length > 0 ? (
            <ul className="grid grid-cols-1 gap-3 md:grid-cols-2 lg:grid-cols-3">
              {jobs.map((job) => (
                <li key={job.id}>
                  <JobCard job={job} />
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-muted-foreground">{tl("empty")}</p>
          )}
        </section>

        {/* Sideways links: the other thirteen regions, so a visitor (and a
            crawler) can move across the whole set from any one of them. */}
        <section className="mt-10">
          <h2 className="text-foreground mb-3 text-xl font-bold">
            {t("otherRegions")}
          </h2>
          <ul className="flex flex-wrap gap-2">
            {UZ_REGION_NAMES.filter((r) => r !== name).map((r) => (
              <li key={r}>
                <Link
                  href={`/hudud/${slugify(r)}`}
                  className="border-border bg-card hover:border-primary/40 inline-block rounded-full border px-3 py-1.5 text-sm transition-colors"
                >
                  {r}
                </Link>
              </li>
            ))}
          </ul>
        </section>
      </Container>

      <FaqSection
        heading={tfaq("heading", { region: name })}
        items={faqItems}
      />
    </>
  );
}
