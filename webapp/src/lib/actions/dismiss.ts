"use server";

import { createClient } from "@/lib/supabase/server";

export interface ToggleDismissResult {
  dismissed: boolean;
  signedOut?: boolean;
}

/**
 * Toggles a job as "archived" / not interested for the signed-in seeker —
 * mirrors toggleBookmark's shape. A dismissed job is excluded from the open-
 * jobs feed (getOpenJobs / getRecentJobs, 0052) but stays visible if bookmarked
 * or linked to directly; toggling again restores it to the feed.
 */
export async function toggleDismiss(
  jobId: string,
): Promise<ToggleDismissResult> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { dismissed: false, signedOut: true };

  const { data: existing } = await supabase
    .from("dismissed_jobs")
    .select("job_id")
    .eq("profile_id", user.id)
    .eq("job_id", jobId)
    .maybeSingle();

  if (existing) {
    await supabase
      .from("dismissed_jobs")
      .delete()
      .eq("profile_id", user.id)
      .eq("job_id", jobId);
    return { dismissed: false };
  }

  await supabase
    .from("dismissed_jobs")
    .insert({ profile_id: user.id, job_id: jobId });
  return { dismissed: true };
}
