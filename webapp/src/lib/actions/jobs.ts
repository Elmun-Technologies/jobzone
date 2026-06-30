"use server";

import { getOpenJobs } from "@/lib/data/jobs";
import type { Job, JobQuery } from "@/lib/data/types";

/** Fetches the next page of open jobs for the "Load more" control. */
export async function loadMoreJobs(
  query: JobQuery,
  offset: number,
): Promise<Job[]> {
  return getOpenJobs({ ...query, offset });
}
