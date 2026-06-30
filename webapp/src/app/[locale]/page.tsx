import { Search } from "lucide-react";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { JobCard } from "@/components/jobs/job-card";
import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { getCategories } from "@/lib/data/categories";
import { getRecentJobs } from "@/lib/data/jobs";
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

  const [recent, categories] = await Promise.all([
    getRecentJobs(6),
    getCategories(),
  ]);

  return (
    <>
      {/* Hero */}
      <Container className="py-16 sm:py-24">
        <div className="mx-auto flex max-w-2xl flex-col items-center gap-6 text-center">
          <h1 className="text-foreground text-4xl font-bold tracking-tight sm:text-5xl">
            {t("heroTitle")}
          </h1>
          <p className="text-muted-foreground text-lg">{t("heroSubtitle")}</p>

          <form
            action={`/${locale}/jobs`}
            className="border-border bg-card flex w-full max-w-xl items-center gap-2 rounded-full border p-2 shadow-sm"
          >
            <Search className="text-muted-foreground ml-3 size-5 shrink-0" />
            <input
              name="q"
              placeholder={t("searchPlaceholder")}
              className="text-foreground placeholder:text-muted-foreground h-10 flex-1 bg-transparent px-1 outline-none"
            />
            <button
              type="submit"
              className={cn(buttonVariants({ variant: "primary", size: "sm" }))}
            >
              {t("searchCta")}
            </button>
          </form>

          {/* Category chips */}
          {categories.length > 0 ? (
            <div className="flex flex-wrap justify-center gap-2">
              {categories.slice(0, 8).map((c) => (
                <Link
                  key={c.id}
                  href={`/jobs?category=${encodeURIComponent(c.name)}`}
                  className="border-border bg-background text-foreground hover:border-primary hover:text-primary rounded-full border px-4 py-1.5 text-sm font-medium transition-colors"
                >
                  {c.name}
                </Link>
              ))}
            </div>
          ) : null}
        </div>
      </Container>

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
                <JobCard job={job} />
              </li>
            ))}
          </ul>
        </Container>
      ) : null}
    </>
  );
}
