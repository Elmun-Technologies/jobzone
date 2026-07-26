"use server";

import { createClient } from "@/lib/supabase/server";

export interface ToggleDismissResult {
  dismissed: boolean;
  signedOut?: boolean;
  /** The write failed — `dismissed` carries the state that is still true on
   * the server, so the caller can put its optimistic UI back. */
  error?: boolean;
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
    const { error } = await supabase
      .from("dismissed_jobs")
      .delete()
      .eq("profile_id", user.id)
      .eq("job_id", jobId);
    // Still archived on the server — say so rather than letting the
    // caller's optimistic "restored" state stand.
    if (error) return { dismissed: true, error: true };
    return { dismissed: false };
  }

  const { error } = await supabase
    .from("dismissed_jobs")
    .insert({ profile_id: user.id, job_id: jobId });
  // 23505 = the row already exists, which is the state the user asked for.
  if (error && error.code !== "23505") return { dismissed: false, error: true };
  return { dismissed: true };
}
