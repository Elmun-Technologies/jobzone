"use server";

import { createClient } from "@/lib/supabase/server";

export interface ToggleResult {
  saved: boolean;
  signedOut?: boolean;
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
    await supabase
      .from("bookmarks")
      .delete()
      .eq("id", (existing as { id: string }).id);
    return { saved: false };
  }

  await supabase
    .from("bookmarks")
    .insert({ profile_id: user.id, job_id: jobId });
  return { saved: true };
}
