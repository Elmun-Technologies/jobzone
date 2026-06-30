import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { JobCard } from "@/components/jobs/job-card";
import { JobSearchControls } from "@/components/jobs/job-search-controls";
import { Container } from "@/components/ui/container";
import { EmptyState } from "@/components/ui/states";
import { getBookmarkedJobIds } from "@/lib/data/bookmarks";
import { getOpenJobs } from "@/lib/data/jobs";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "jobs" });
  return { title: t("title") };
}

export default async function JobsPage({
  params,
  searchParams,
}: {
  params: Promise<{ locale: string }>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  const sp = await searchParams;
  const t = await getTranslations("jobs");

  const pick = (v: string | string[] | undefined) =>
    Array.isArray(v) ? v[0] : v;

  const [jobs, savedIds] = await Promise.all([
    getOpenJobs({
      q: pick(sp.q),
      category: pick(sp.category),
      jobType: pick(sp.jobType),
      workingModel: pick(sp.workingModel),
      limit: 30,
    }),
    getBookmarkedJobIds(),
  ]);

  return (
    <Container className="py-8">
      <h1 className="text-foreground mb-6 text-2xl font-bold sm:text-3xl">
        {t("title")}
      </h1>

      <JobSearchControls />

      <div className="mt-6">
        {jobs.length === 0 ? (
          <EmptyState title={t("resultsZero")} />
        ) : (
          <ul className="grid grid-cols-1 gap-3 lg:grid-cols-2">
            {jobs.map((job) => (
              <li key={job.id}>
                <JobCard job={job} saved={savedIds.has(job.id)} />
              </li>
            ))}
          </ul>
        )}
      </div>
    </Container>
  );
}
