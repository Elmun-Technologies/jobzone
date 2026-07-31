"use server";

import { createClient } from "@/lib/supabase/server";

export interface ToggleResult {
  saved: boolean;
  signedOut?: boolean;
  /** The write failed — `saved` carries the state that is still true on the
   * server, so the caller can put its optimistic UI back. */
  error?: boolean;
}

/** Toggles a bookmark for the signed-in user; returns the new saved state. */
export async function toggleBookmark(jobId: string): Promise<ToggleResult> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { saved: false, signedOut: true };

  const { data: existing } = await supabase
    .from("bookmarks")
    .select("id")
    .eq("profile_id", user.id)
    .eq("job_id", jobId)
    .maybeSingle();

  if (existing) {
    const { error } = await supabase
      .from("bookmarks")
      .delete()
      .eq("id", (existing as { id: string }).id);
    // The row is still there, so report it as still saved rather than
    // letting the caller's optimistic "removed" state stand.
    if (error) return { saved: true, error: true };
    return { saved: false };
  }

  const { error } = await supabase
    .from("bookmarks")
    .insert({ profile_id: user.id, job_id: jobId });
  // 23505 = unique(profile_id, job_id): a double tap raced us and the
  // bookmark exists, which is the state the user asked for — not an error.
  if (error && error.code !== "23505") return { saved: false, error: true };
  return { saved: true };
}
