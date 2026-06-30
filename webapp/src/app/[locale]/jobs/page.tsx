import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { JobFilters } from "@/components/jobs/job-filters";
import { JobResults } from "@/components/jobs/job-results";
import { JobToolbar } from "@/components/jobs/job-toolbar";
import { Container } from "@/components/ui/container";
import { getBookmarkedJobIds } from "@/lib/data/bookmarks";
import { getCities, getJobCount, getOpenJobs } from "@/lib/data/jobs";
import type { JobQuery } from "@/lib/data/types";
import { groupNumber } from "@/lib/format";

const PAGE_SIZE = 20;

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
  const num = (v: string | string[] | undefined) => {
    const n = Number(pick(v));
    return Number.isFinite(n) && n > 0 ? n : undefined;
  };

  const query: JobQuery = {
    q: pick(sp.q),
    category: pick(sp.category),
    city: pick(sp.city),
    jobType: pick(sp.jobType),
    workingModel: pick(sp.workingModel),
    experienceLevel: pick(sp.experienceLevel),
    salaryMin: num(sp.salaryMin),
    currency: pick(sp.currency),
    postedWithin: num(sp.postedWithin),
    sort: pick(sp.sort),
    limit: PAGE_SIZE,
  };

  const [jobs, count, cities, savedIds] = await Promise.all([
    getOpenJobs(query),
    getJobCount(query),
    getCities(),
    getBookmarkedJobIds(),
  ]);

  const view = pick(sp.view) === "grid" ? "grid" : "list";
  const title = query.category ?? t("title");

  return (
    <Container className="py-8">
      <div className="grid gap-6 lg:grid-cols-[1fr_320px]">
        {/* Filters — top on mobile, right column on desktop */}
        <aside className="lg:col-start-2 lg:row-start-1">
          <JobFilters cities={cities} />
        </aside>

        {/* Results */}
        <main className="min-w-0 lg:col-start-1 lg:row-start-1">
          <div className="mb-4">
            <h1 className="text-foreground text-xl font-bold sm:text-2xl">
              {title}
            </h1>
            <p className="text-muted-foreground mt-0.5 text-sm">
              {t("resultsCount", { count: groupNumber(count) })}
            </p>
          </div>

          <JobToolbar />

          <JobResults
            key={`${JSON.stringify(query)}|${view}`}
            initial={jobs}
            savedIds={[...savedIds]}
            query={query}
            total={count}
            pageSize={PAGE_SIZE}
            view={view}
          />
        </main>
      </div>
    </Container>
  );
}
