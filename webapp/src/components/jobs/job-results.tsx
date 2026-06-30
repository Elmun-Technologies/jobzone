"use client";

import { useTranslations } from "next-intl";
import { useState, useTransition } from "react";

import { buttonVariants } from "@/components/ui/button";
import { EmptyState } from "@/components/ui/states";
import { loadMoreJobs } from "@/lib/actions/jobs";
import type { Job, JobQuery } from "@/lib/data/types";
import { cn } from "@/lib/utils";

import { JobCard } from "./job-card";

/**
 * Renders the jobs grid and a "Load more" control that appends the next page
 * via a server action. Remount it (key on the active query) to reset to a
 * fresh first page when filters change.
 */
export function JobResults({
  initial,
  savedIds,
  query,
  total,
  pageSize,
  view,
}: {
  initial: Job[];
  savedIds: string[];
  query: JobQuery;
  total: number;
  pageSize: number;
  view: "list" | "grid";
}) {
  const t = useTranslations("jobs");
  const tc = useTranslations("common");
  const [jobs, setJobs] = useState<Job[]>(initial);
  const [done, setDone] = useState(false);
  const [pending, startTransition] = useTransition();
  const saved = new Set(savedIds);

  function loadMore() {
    startTransition(async () => {
      const more = await loadMoreJobs(query, jobs.length);
      if (more.length < pageSize) setDone(true);
      setJobs((prev) => {
        const seen = new Set(prev.map((j) => j.id));
        return [...prev, ...more.filter((j) => !seen.has(j.id))];
      });
    });
  }

  if (jobs.length === 0) return <EmptyState title={t("resultsZero")} />;

  const hasMore = !done && jobs.length < total;

  return (
    <div>
      <ul
        className={cn(
          "grid gap-3",
          view === "grid" ? "sm:grid-cols-2" : "grid-cols-1",
        )}
      >
        {jobs.map((job) => (
          <li key={job.id}>
            <JobCard job={job} saved={saved.has(job.id)} />
          </li>
        ))}
      </ul>

      {hasMore ? (
        <div className="mt-6 flex justify-center">
          <button
            type="button"
            onClick={loadMore}
            disabled={pending}
            className={cn(buttonVariants({ variant: "outline", size: "md" }))}
          >
            {pending ? tc("loading") : t("loadMore")}
          </button>
        </div>
      ) : null}
    </div>
  );
}
