import { BadgeCheck, MapPin } from "lucide-react";
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { JsonLd } from "@/components/seo/json-ld";
import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { getJobById } from "@/lib/data/jobs";
import { formatDate, locationText, salaryText } from "@/lib/format";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";
import { jobPostingJsonLd, siteUrl } from "@/lib/seo";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string; id: string }>;
}): Promise<Metadata> {
  const { locale, id } = await params;
  const job = await getJobById(id);
  if (!job) return { title: "Job" };
  const loc = locationText(job);
  const title = `${job.title} — ${job.companyName}`;
  const description =
    job.description?.slice(0, 155) ??
    `${job.title} at ${job.companyName}${loc ? ` · ${loc}` : ""}`;
  const url = `${siteUrl()}/${locale}/jobs/${id}`;
  return {
    title,
    description,
    alternates: { canonical: url },
    openGraph: { title, description, url, type: "website" },
    twitter: { card: "summary", title, description },
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

  return (
    <Container className="py-8">
      <JsonLd data={jobPostingJsonLd(job)} />

      <div className="grid grid-cols-1 gap-8 lg:grid-cols-3">
        {/* Main column */}
        <div className="lg:col-span-2">
          <div className="flex gap-4">
            {job.companyLogoUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={job.companyLogoUrl}
                alt={job.companyName}
                width={64}
                height={64}
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
        </div>

        {/* Sidebar */}
        <aside className="lg:col-span-1">
          <div className="border-border bg-card sticky top-20 rounded-xl border p-5">
            <p className="text-muted-foreground text-sm">{t("salary")}</p>
            <p className="text-foreground mt-1 text-xl font-bold">
              {salary ?? t("negotiable")}
            </p>
            <Link
              href="/sign-in"
              className={cn(
                buttonVariants({ variant: "primary", size: "lg" }),
                "mt-4 w-full",
              )}
            >
              {t("apply")}
            </Link>
            {job.postedAt ? (
              <p className="text-muted-foreground mt-3 text-center text-xs">
                {t("postedOn")} {formatDate(job.postedAt)}
              </p>
            ) : null}
          </div>
        </aside>
      </div>
    </Container>
  );
}
