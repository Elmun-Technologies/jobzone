import { BadgeCheck, Globe, MapPin, Star } from "lucide-react";
import type { Metadata } from "next";
import Image from "next/image";
import { notFound } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { JobCard } from "@/components/jobs/job-card";
import { JsonLd } from "@/components/seo/json-ld";
import { Container } from "@/components/ui/container";
import { getBookmarkedJobIds } from "@/lib/data/bookmarks";
import {
  getCompanyById,
  getCompanyJobs,
  getCompanyReviews,
} from "@/lib/data/companies";
import { formatDate } from "@/lib/format";
import {
  breadcrumbJsonLd,
  localeAlternates,
  organizationJsonLd,
  siteUrl,
} from "@/lib/seo";

// Auth/session-dependent, per-request. Without this the page can be
// full-route-cached (getCurrentUser swallows cookies() so Next never sees
// the dynamic signal) and one visitor's render could be served to another.
export const dynamic = "force-dynamic";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string; id: string }>;
}): Promise<Metadata> {
  const { locale, id } = await params;
  const company = await getCompanyById(id);
  if (!company) {
    const t = await getTranslations({ locale, namespace: "common" });
    return { title: t("notFound") };
  }
  const description =
    company.about?.slice(0, 155) ?? `${company.name} on Yolla`;
  const url = `${siteUrl()}/${locale}/companies/${id}`;
  return {
    title: company.name,
    description,
    alternates: localeAlternates(locale, `companies/${id}`),
    openGraph: { title: company.name, description, url, type: "website" },
  };
}

export default async function CompanyPage({
  params,
}: {
  params: Promise<{ locale: string; id: string }>;
}) {
  const { locale, id } = await params;
  setRequestLocale(locale);
  const company = await getCompanyById(id);
  if (!company) notFound();

  const t = await getTranslations("company");
  const [jobs, reviews, savedIds] = await Promise.all([
    getCompanyJobs(id),
    getCompanyReviews(id),
    getBookmarkedJobIds(),
  ]);

  const tb = await getTranslations("landingPage");
  const base = siteUrl();
  const localePath = `${base}/${locale}`;

  return (
    <Container className="py-8">
      <JsonLd data={organizationJsonLd(company)} />
      <JsonLd
        data={breadcrumbJsonLd([
          { name: tb("breadcrumbHome"), url: localePath },
          { name: t("directoryTitle"), url: `${localePath}/companies` },
          { name: company.name, url: `${localePath}/companies/${id}` },
        ])}
      />

      {/* Header */}
      <div className="flex gap-4">
        {company.logoUrl ? (
          <Image
            src={company.logoUrl}
            alt={company.name}
            width={72}
            height={72}
            priority
            sizes="72px"
            className="size-[72px] shrink-0 rounded-xl object-cover"
          />
        ) : (
          <div className="bg-primary text-primary-foreground flex size-[72px] shrink-0 items-center justify-center rounded-xl text-3xl font-bold">
            {company.name.charAt(0).toUpperCase()}
          </div>
        )}
        <div className="min-w-0">
          <h1 className="text-foreground flex items-center gap-2 text-2xl font-bold">
            {company.name}
            {company.isVerified ? (
              <BadgeCheck className="text-primary size-5" />
            ) : null}
          </h1>
          <p className="text-muted-foreground mt-1 text-sm">
            {[company.industry, company.size].filter(Boolean).join(" · ")}
          </p>
          <div className="text-muted-foreground mt-2 flex flex-wrap gap-4 text-sm">
            {company.headquarters ? (
              <span className="flex items-center gap-1">
                <MapPin className="size-4" />
                {company.headquarters}
              </span>
            ) : null}
            {company.website ? (
              <a
                href={
                  /^https?:\/\//i.test(company.website)
                    ? company.website
                    : `https://${company.website}`
                }
                target="_blank"
                rel="noopener noreferrer"
                className="text-primary flex items-center gap-1 hover:underline"
              >
                <Globe className="size-4" />
                {t("visitWebsite")}
              </a>
            ) : null}
          </div>
        </div>
      </div>

      {company.about ? (
        <section className="mt-8">
          <h2 className="text-foreground mb-2 text-lg font-semibold">
            {t("about")}
          </h2>
          <p className="text-muted-foreground text-sm leading-relaxed whitespace-pre-wrap">
            {company.about}
          </p>
        </section>
      ) : null}

      <section className="mt-8">
        <h2 className="text-foreground mb-3 text-lg font-semibold">
          {t("openJobs")} ({jobs.length})
        </h2>
        {jobs.length === 0 ? (
          <p className="text-muted-foreground text-sm">{t("noOpenJobs")}</p>
        ) : (
          <ul className="grid grid-cols-1 gap-3 lg:grid-cols-2">
            {jobs.map((job) => (
              <li key={job.id}>
                <JobCard job={job} saved={savedIds.has(job.id)} />
              </li>
            ))}
          </ul>
        )}
      </section>

      <section className="mt-8">
        <h2 className="text-foreground mb-3 text-lg font-semibold">
          {t("reviews")}
        </h2>
        {reviews.length === 0 ? (
          <p className="text-muted-foreground text-sm">{t("noReviews")}</p>
        ) : (
          <ul className="space-y-3">
            {reviews.map((r) => (
              <li
                key={r.id}
                className="border-border bg-card rounded-xl border p-4"
              >
                <div className="flex items-center gap-1 text-amber-500">
                  {Array.from({ length: 5 }).map((_, i) => (
                    <Star
                      key={i}
                      className="size-4"
                      fill={i < r.rating ? "currentColor" : "none"}
                    />
                  ))}
                  {r.createdAt ? (
                    <span className="text-muted-foreground ml-2 text-xs">
                      {formatDate(r.createdAt)}
                    </span>
                  ) : null}
                </div>
                {r.body ? (
                  <p className="text-muted-foreground mt-2 text-sm">{r.body}</p>
                ) : null}
              </li>
            ))}
          </ul>
        )}
      </section>
    </Container>
  );
}
