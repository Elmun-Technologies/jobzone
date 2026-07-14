import type { Metadata } from "next";

import { routing } from "@/i18n/routing";
import type { Company, Job } from "@/lib/data/types";

/** Canonical site origin, e.g. https://www.yollla.uz (no trailing slash).
 * Every absolute URL the crawler sees — metadataBase, canonical, og:url,
 * sitemap entries, robots' Sitemap: line — resolves through this one call, so
 * a domain change is a single-file swap. Vercel Production/Preview MUST set
 * NEXT_PUBLIC_SITE_URL for the correct origin; the default is the brand
 * apex used at launch and is what the sitemap serves when the env is unset. */
export function siteUrl(): string {
  return (
    process.env.NEXT_PUBLIC_SITE_URL?.replace(/\/$/, "") ??
    "https://www.yollla.uz"
  );
}

const EMPLOYMENT_TYPE: Record<string, string> = {
  full_time: "FULL_TIME",
  part_time: "PART_TIME",
  contract: "CONTRACTOR",
  temporary: "TEMPORARY",
  internship: "INTERN",
  rotational: "OTHER",
};

const SALARY_UNIT: Record<string, string> = {
  hour: "HOUR",
  day: "DAY",
  week: "WEEK",
  month: "MONTH",
  year: "YEAR",
};

function descriptionHtml(job: Job): string {
  const parts = [
    job.description,
    job.responsibilities &&
      `<h3>Responsibilities</h3><p>${job.responsibilities}</p>`,
    job.requirements && `<h3>Requirements</h3><p>${job.requirements}</p>`,
    job.benefits && `<h3>Benefits</h3><p>${job.benefits}</p>`,
  ].filter(Boolean);
  return parts.length ? parts.join("\n") : job.title;
}

/**
 * schema.org JobPosting structured data — makes a job eligible for the Google
 * Jobs widget. Embed via a <script type="application/ld+json"> on the job page.
 */
export function jobPostingJsonLd(job: Job): Record<string, unknown> {
  const data: Record<string, unknown> = {
    "@context": "https://schema.org/",
    "@type": "JobPosting",
    title: job.title,
    description: descriptionHtml(job),
    datePosted: job.postedAt ?? undefined,
    validThrough: job.expiresAt ?? undefined,
    employmentType: (job.jobType && EMPLOYMENT_TYPE[job.jobType]) ?? undefined,
    hiringOrganization: {
      "@type": "Organization",
      name: job.companyName,
      logo: job.companyLogoUrl ?? undefined,
    },
    jobLocation: {
      "@type": "Place",
      address: {
        "@type": "PostalAddress",
        addressLocality: job.city ?? undefined,
        addressCountry: job.country ?? "UZ",
      },
    },
  };

  if (job.workingModel === "remote") {
    data.jobLocationType = "TELECOMMUTE";
  }

  if (job.salaryMin != null || job.salaryMax != null) {
    data.baseSalary = {
      "@type": "MonetaryAmount",
      currency: job.currency,
      value: {
        "@type": "QuantitativeValue",
        minValue: job.salaryMin ?? undefined,
        maxValue: job.salaryMax ?? job.salaryMin ?? undefined,
        unitText: SALARY_UNIT[job.salaryPeriod] ?? "MONTH",
      },
    };
  }

  return data;
}

/** schema.org Organization structured data for a company page. */
export function organizationJsonLd(company: Company): Record<string, unknown> {
  return {
    "@context": "https://schema.org/",
    "@type": "Organization",
    name: company.name,
    logo: company.logoUrl ?? undefined,
    url: company.website ?? undefined,
    description: company.about ?? undefined,
    address: company.headquarters
      ? { "@type": "PostalAddress", addressLocality: company.headquarters }
      : undefined,
  };
}

/** Renders a JSON-LD <script>. Strips undefined via JSON.stringify. */
export function jsonLdScript(data: Record<string, unknown>): string {
  return JSON.stringify(data);
}

/** A locale-prefixed path like "/uz/jobs/abc" — used to build canonical +
 * hreflang alternate URLs from a single input. Empty path → the locale root. */
function localePath(locale: string, path: string): string {
  const clean = path.replace(/^\/+/, "").replace(/\/+$/, "");
  return clean ? `/${locale}/${clean}` : `/${locale}`;
}

/**
 * `alternates` block for a page that has a URL in every supported locale.
 *
 * - `canonical`: the current locale's absolute URL (self-referencing — no
 *   duplicate-content signal to Google when a page is reachable via a
 *   trailing slash, a lowercased path, etc.).
 * - `languages`: uz/ru/en alternates + an `x-default` pointing at the default
 *   locale (uz) — how Google picks the right locale for each searcher.
 *
 * Pass an unprefixed path ("jobs", "companies/abc", "" for root). Every
 * `generateMetadata` in the app should call this so alternates stay in sync
 * as new locales are added.
 */
export function localeAlternates(
  locale: string,
  path: string,
): NonNullable<Metadata["alternates"]> {
  const base = siteUrl();
  const languages: Record<string, string> = {};
  for (const loc of routing.locales) {
    languages[loc] = `${base}${localePath(loc, path)}`;
  }
  languages["x-default"] = `${base}${localePath(routing.defaultLocale, path)}`;
  return {
    canonical: `${base}${localePath(locale, path)}`,
    languages,
  };
}
