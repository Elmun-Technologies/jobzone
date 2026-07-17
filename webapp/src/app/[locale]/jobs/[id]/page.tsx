import { BadgeCheck, MapPin } from "lucide-react";
import type { Metadata } from "next";
import Image from "next/image";
import { notFound } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { PageEvent } from "@/components/analytics/page-event";
import { JsonLd } from "@/components/seo/json-ld";
import { Container } from "@/components/ui/container";
import { BookmarkButton } from "@/components/jobs/bookmark-button";
import { PhoneLink } from "@/components/jobs/phone-link";
import { QuickApplyButton } from "@/components/jobs/quick-apply-button";
import { ShareCreative } from "@/components/jobs/share-creative";
import { hasApplied } from "@/lib/data/applications";
import { isBookmarked } from "@/lib/data/bookmarks";
import { getJobById } from "@/lib/data/jobs";
import { getCurrentUser } from "@/lib/auth/user";
import {
  formatDate,
  locationText,
  salaryText,
  schedulePatternLabel,
} from "@/lib/format";
import { Link } from "@/i18n/navigation";
import {
  breadcrumbJsonLd,
  jobPostingJsonLd,
  localeAlternates,
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
  const job = await getJobById(id);
  if (!job) {
    const t = await getTranslations({ locale, namespace: "common" });
    return { title: t("notFound") };
  }
  const loc = locationText(job);
  const salary = salaryText(job);
  // "Kassir — Toshkent | 4 000 000 so'm | Yolla" — the exact query shape
  // seekers type into Google. City goes right after the job title so the
  // "toshkentda kassir" tail matches; salary joins when we have it. Yolla
  // is appended by the layout template so it isn't duplicated here.
  const titleParts = [job.title, loc, salary].filter(Boolean).join(" — ");
  const title = titleParts || job.title;
  // Description leads with the raw posting when we have one; otherwise a
  // synthesized one liner in the seeker's language stays keyword-rich.
  const description = (
    job.description?.slice(0, 155) ??
    [
      job.title,
      job.companyName,
      loc,
      salary,
      schedulePatternLabel(job.schedulePattern),
    ]
      .filter(Boolean)
      .join(" · ")
  ).slice(0, 160);
  const url = `${siteUrl()}/${locale}/jobs/${id}`;
  return {
    title,
    description,
    alternates: localeAlternates(locale, `jobs/${id}`),
    // The `opengraph-image` file in this segment supplies og:image /
    // twitter:image automatically, so a shared job link renders a branded card.
    openGraph: { title, description, url, type: "website" },
    twitter: { card: "summary_large_image", title, description },
  };
}

function Section({ title, body }: { title: string; body: string | null }) {
  if (!body) return null;
  return (
    <section className="mt-6">
      <h2 className="text-foreground mb-2 text-lg font-semibold">{title}</h2>
      <p className="text-muted-foreground text-sm leading-relaxed whitespace-pre-wrap">
        {body}
      </p>
    </section>
  );
}

export default async function JobDetailsPage({
  params,
}: {
  params: Promise<{ locale: string; id: string }>;
}) {
  const { locale, id } = await params;
  setRequestLocale(locale);
  const job = await getJobById(id);
  if (!job) notFound();

  const t = await getTranslations("jobs");
  const salary = salaryText(job);
  const loc = locationText(job);

  // Employment "at a glance" chips (neutral) — most are already on the Job.
  // t.has guards against any legacy enum value the CHECK constraints wouldn't
  // normally allow, so a stray value degrades to "hidden" not a thrown key.
  const label = (ns: string, v: string | null) =>
    v && t.has(`${ns}.${v}`) ? t(`${ns}.${v}`) : null;
  const metaChips = [
    job.categoryName,
    label("type", job.jobType),
    label("model", job.workingModel),
    label("exp", job.experienceLevel),
    job.schedulePattern &&
      (schedulePatternLabel(job.schedulePattern) ?? t("scheduleCustom")),
  ].filter(Boolean) as string[];
  // Positive accessibility/shift flags — highlighted (volt-tinted).
  const flagChips = [
    job.nightShift && t("nightShift"),
    job.womenFriendly && t("womenFriendly"),
    job.disabilityFriendly && t("disabilityFriendly"),
  ].filter(Boolean) as string[];
  // "Conditions" fact rows (label → value).
  const facts: { label: string; value: string }[] = [];
  if (job.formalization)
    facts.push({
      label: t("formalization"),
      value: t(`formValues.${job.formalization}`),
    });
  if (job.educationRequired)
    facts.push({
      label: t("education"),
      value: t(`eduValues.${job.educationRequired}`),
    });
  if (job.workHours)
    facts.push({ label: t("workHours"), value: job.workHours });
  if (job.salaryMin != null || job.salaryMax != null)
    facts.push({
      label: t("payType"),
      value: job.salaryGross ? t("gross") : t("net"),
    });
  if (job.driverLicenses.length)
    facts.push({
      label: t("driverLicense"),
      value: job.driverLicenses.join(", "),
    });
  if (job.languages.length)
    facts.push({
      label: t("requiredLanguages"),
      value: job.languages
        .map((l) => {
          const name = t.has(`langNames.${l.code}`)
            ? t(`langNames.${l.code}`)
            : l.code.toUpperCase();
          const lvl =
            l.level === "native" ? t("langLevelNative") : l.level.toUpperCase();
          return lvl ? `${name} · ${lvl}` : name;
        })
        .join(", "),
    });

  const user = await getCurrentUser();
  const [applied, bookmarked] = await Promise.all([
    user ? hasApplied(job.id) : Promise.resolve(false),
    user ? isBookmarked(job.id) : Promise.resolve(false),
  ]);
  // A job needs the full apply form only when it has a required screening
  // question (the sidebar CTA one-taps otherwise). Guest-first throughout:
  // QuickApplyButton routes an unauthenticated tap to sign-in and back.
  const needsForm = job.screeningQuestions.some((q) => q.required);

  const tb = await getTranslations("landingPage");
  const base = siteUrl();
  const localePath = `${base}/${locale}`;

  return (
    <Container className="py-8">
      <JsonLd data={jobPostingJsonLd(job)} />
      <JsonLd
        data={breadcrumbJsonLd([
          { name: tb("breadcrumbHome"), url: localePath },
          { name: tb("breadcrumbJobs"), url: `${localePath}/jobs` },
          { name: job.title, url: `${localePath}/jobs/${id}` },
        ])}
      />
      <PageEvent
        name="job_view"
        props={{
          job_id: job.id,
          company_id: job.companyId,
          category: job.categoryName ?? null,
          city: job.city ?? null,
          salary_max: job.salaryMax ?? null,
        }}
      />

      <div className="grid grid-cols-1 gap-8 lg:grid-cols-3">
        {/* Main column */}
        <div className="lg:col-span-2">
          <div className="flex gap-4">
            {job.companyLogoUrl ? (
              <Image
                src={job.companyLogoUrl}
                alt={job.companyName}
                width={64}
                height={64}
                // Above-the-fold on the detail page — priority hints
                // the browser to fetch it in the first batch. Fixed 64px
                // slot; one srcset entry is enough.
                priority
                sizes="64px"
                className="size-16 shrink-0 rounded-xl object-cover"
              />
            ) : (
              <div className="bg-primary text-primary-foreground flex size-16 shrink-0 items-center justify-center rounded-xl text-2xl font-bold">
                {job.companyName.charAt(0).toUpperCase()}
              </div>
            )}
            <div className="min-w-0">
              <h1 className="text-foreground text-2xl font-bold">
                {job.title}
              </h1>
              <Link
                href={`/companies/${job.companyId}`}
                className="text-muted-foreground hover:text-primary mt-1 inline-flex items-center gap-1"
              >
                {job.companyName}
                {job.companyVerified ? (
                  <BadgeCheck className="text-primary size-4" />
                ) : null}
              </Link>
              {loc ? (
                <div className="text-muted-foreground mt-1 flex items-center gap-1 text-sm">
                  <MapPin className="size-3.5" />
                  {loc}
                </div>
              ) : null}
            </div>
          </div>

          {metaChips.length || flagChips.length ? (
            <div className="mt-4 flex flex-wrap gap-2">
              {metaChips.map((c) => (
                <span
                  key={c}
                  className="border-border bg-muted text-foreground rounded-full border px-3 py-1 text-sm font-medium"
                >
                  {c}
                </span>
              ))}
              {flagChips.map((c) => (
                <span
                  key={c}
                  className="border-primary/40 bg-accent text-accent-foreground rounded-full border px-3 py-1 text-sm font-medium"
                >
                  {c}
                </span>
              ))}
            </div>
          ) : null}

          <Section title={t("aboutRole")} body={job.description} />
          <Section title={t("responsibilities")} body={job.responsibilities} />
          <Section title={t("requirements")} body={job.requirements} />
          <Section title={t("benefits")} body={job.benefits} />

          {job.skills.length > 0 ? (
            <section className="mt-6">
              <h2 className="text-foreground mb-2 text-lg font-semibold">
                {t("skills")}
              </h2>
              <div className="flex flex-wrap gap-2">
                {job.skills.map((s) => (
                  <span
                    key={s}
                    className="bg-muted text-muted-foreground rounded-full px-3 py-1 text-sm"
                  >
                    {s}
                  </span>
                ))}
              </div>
            </section>
          ) : null}

          {facts.length > 0 ? (
            <section className="mt-6">
              <h2 className="text-foreground mb-2 text-lg font-semibold">
                {t("conditions")}
              </h2>
              <dl className="border-border bg-card divide-border divide-y rounded-xl border">
                {facts.map((f) => (
                  <div
                    key={f.label}
                    className="flex items-start justify-between gap-4 px-4 py-3"
                  >
                    <dt className="text-muted-foreground text-sm">{f.label}</dt>
                    <dd className="text-foreground text-right text-sm font-medium">
                      {f.value}
                    </dd>
                  </div>
                ))}
              </dl>
            </section>
          ) : null}
        </div>

        {/* Sidebar */}
        <aside className="lg:col-span-1">
          <div className="border-border bg-card sticky top-20 rounded-xl border p-5">
            <p className="text-muted-foreground text-sm">{t("salary")}</p>
            <p className="text-foreground mt-1 text-xl font-bold">
              {salary ?? t("negotiable")}
            </p>
            {applied ? (
              <p className="bg-muted text-muted-foreground mt-4 w-full rounded-full py-3 text-center text-sm font-semibold">
                {t("applied")}
              </p>
            ) : (
              <QuickApplyButton
                jobId={id}
                needsForm={needsForm}
                className="mt-4 h-12 w-full text-base"
              />
            )}
            <BookmarkButton
              jobId={id}
              initial={bookmarked}
              className="mt-2 w-full justify-center"
            />
            {job.contactPhone ? (
              <PhoneLink
                phone={job.contactPhone}
                jobId={job.id}
                companyId={job.companyId}
              />
            ) : null}
            {job.postedAt ? (
              <p className="text-muted-foreground mt-3 text-center text-xs">
                {t("postedOn")} {formatDate(job.postedAt)}
              </p>
            ) : null}
          </div>

          <ShareCreative
            basePath={`/${locale}/jobs/${id}`}
            shareUrl={`${siteUrl()}/${locale}/jobs/${id}`}
            title={job.title}
          />
        </aside>
      </div>
    </Container>
  );
}
