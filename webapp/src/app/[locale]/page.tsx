import { ChevronRight, Search, TrendingUp } from "lucide-react";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { CompanyCard } from "@/components/companies/company-card";
import { JobCard } from "@/components/jobs/job-card";
import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { categoryEmoji } from "@/lib/categories-meta";
import { getBookmarkedJobIds } from "@/lib/data/bookmarks";
import { getCategoriesWithCounts } from "@/lib/data/categories";
import { getCompanies } from "@/lib/data/companies";
import { getCities, getJobCount, getRecentJobs } from "@/lib/data/jobs";
import { groupNumber } from "@/lib/format";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

export default async function HomePage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("home");
  const tj = await getTranslations("jobs");

  const [recent, categories, total, cities, savedIds, topCompanies] =
    await Promise.all([
      getRecentJobs(6),
      getCategoriesWithCounts(),
      getJobCount(),
      getCities(),
      getBookmarkedJobIds(),
      getCompanies({ limit: 8 }),
    ]);

  // Popular-search shortcuts, reusing existing job-filter labels.
  const presets = [
    { label: tj("exp.entry"), href: "/jobs?experienceLevel=entry" },
    { label: tj("model.remote"), href: "/jobs?workingModel=remote" },
    { label: tj("type.part_time"), href: "/jobs?jobType=part_time" },
    { label: tj("type.full_time"), href: "/jobs?jobType=full_time" },
    { label: tj("type.internship"), href: "/jobs?jobType=internship" },
    { label: tj("type.rotational"), href: "/jobs?jobType=rotational" },
  ];

  return (
    <>
      {/* Hero */}
      <Container className="py-14 sm:py-20">
        <div className="mx-auto flex max-w-3xl flex-col items-center gap-5 text-center">
          <h1 className="text-foreground text-4xl font-bold tracking-tight sm:text-5xl">
            {t("heroTitle")}
          </h1>
          <p className="text-muted-foreground text-lg">{t("heroSubtitle")}</p>
          {total > 0 ? (
            <p className="text-muted-foreground text-sm">
              {t("jobCount", { count: groupNumber(total) })}
            </p>
          ) : null}

          <form
            action={`/${locale}/jobs`}
            className="border-border bg-card flex w-full max-w-2xl flex-col gap-2 rounded-2xl border p-2 shadow-sm sm:flex-row sm:items-center sm:rounded-full"
          >
            <div className="flex flex-1 items-center gap-2">
              <Search className="text-muted-foreground ml-2 size-5 shrink-0" />
              <input
                name="q"
                placeholder={t("searchPlaceholder")}
                aria-label={t("searchPlaceholder")}
                className="text-foreground placeholder:text-muted-foreground h-10 w-full flex-1 bg-transparent px-1 outline-none"
              />
            </div>
            <div className="flex items-center gap-2">
              {cities.length > 0 ? (
                <select
                  name="city"
                  defaultValue=""
                  aria-label={t("allRegions")}
                  className="text-foreground bg-muted h-10 max-w-[10rem] rounded-full px-3 text-sm outline-none sm:bg-transparent"
                >
                  <option value="">{t("allRegions")}</option>
                  {cities.map((c) => (
                    <option key={c} value={c}>
                      {c}
                    </option>
                  ))}
                </select>
              ) : null}
              <button
                type="submit"
                className={cn(
                  buttonVariants({ variant: "primary", size: "sm" }),
                  "shrink-0",
                )}
              >
                {t("searchCta")}
              </button>
            </div>
          </form>
        </div>
      </Container>

      {/* Category grid */}
      {categories.length > 0 ? (
        <Container className="pb-16">
          <ul className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
            {categories.map((c) => (
              <li key={c.id}>
                <Link
                  href={`/jobs?category=${encodeURIComponent(c.name)}`}
                  className="border-border bg-card hover:border-primary/40 flex h-full flex-col gap-2 rounded-xl border p-4 transition-all hover:shadow-sm"
                >
                  <span className="text-3xl leading-none">
                    {categoryEmoji(c)}
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
        </Container>
      ) : null}

      {/* Popular searches */}
      <Container className="pb-16">
        <h2 className="text-foreground mb-4 text-xl font-bold">
          {t("popularSearches")}
        </h2>
        <ul className="grid grid-cols-2 gap-3 sm:grid-cols-3">
          {presets.map((p) => (
            <li key={p.href}>
              <Link
                href={p.href}
                className="border-border bg-card hover:border-primary/40 flex items-center justify-between gap-2 rounded-xl border p-4 transition-all hover:shadow-sm"
              >
                <span className="flex min-w-0 items-center gap-2">
                  <span className="bg-accent text-accent-foreground flex size-9 shrink-0 items-center justify-center rounded-full">
                    <TrendingUp className="size-4" />
                  </span>
                  <span className="text-foreground truncate font-medium">
                    {p.label}
                  </span>
                </span>
                <ChevronRight className="text-muted-foreground size-4 shrink-0" />
              </Link>
            </li>
          ))}
        </ul>
      </Container>

      {/* Top companies */}
      {topCompanies.length > 0 ? (
        <Container className="pb-16">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="text-foreground text-xl font-bold">
              {t("topCompanies")}
            </h2>
            <Link
              href="/companies"
              className="text-primary text-sm font-semibold hover:underline"
            >
              {t("viewAll")}
            </Link>
          </div>
          <ul className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
            {topCompanies.map((c) => (
              <li key={c.id}>
                <CompanyCard company={c} />
              </li>
            ))}
          </ul>
        </Container>
      ) : null}

      {/* Recent jobs */}
      {recent.length > 0 ? (
        <Container className="pb-20">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="text-foreground text-xl font-bold">
              {t("recentJobs")}
            </h2>
            <Link
              href="/jobs"
              className="text-primary text-sm font-semibold hover:underline"
            >
              {t("viewAll")}
            </Link>
          </div>
          <ul className="grid grid-cols-1 gap-3 md:grid-cols-2 lg:grid-cols-3">
            {recent.map((job) => (
              <li key={job.id}>
                <JobCard job={job} saved={savedIds.has(job.id)} />
              </li>
            ))}
          </ul>
        </Container>
      ) : null}
    </>
  );
}
