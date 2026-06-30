import "server-only";

import { createClient } from "@/lib/supabase/server";

import { toJob } from "./mappers";
import { hasSupabase } from "./supabase-env";
import type { Job } from "./types";

/** The signed-in user's bookmarked open jobs, newest-saved first. */
export async function getBookmarkedJobs(): Promise<Job[]> {
  if (!hasSupabase()) return [];
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return [];

    const { data: bms, error } = await supabase
      .from("bookmarks")
      .select("job_id, created_at")
      .eq("profile_id", user.id)
      .order("created_at", { ascending: false });
    if (error) throw error;

    const ids = (bms ?? []).map((b) =>
      String((b as { job_id: unknown }).job_id),
    );
    if (ids.length === 0) return [];

    const { data: rows, error: jobsError } = await supabase
      .from("job_feed")
      .select("*")
      .in("id", ids);
    if (jobsError) throw jobsError;

    // Preserve bookmark (most-recent-first) order; job_feed only has open jobs.
    const order = new Map(ids.map((id, i) => [id, i]));
    return (rows ?? [])
      .map(toJob)
      .sort((a, b) => (order.get(a.id) ?? 0) - (order.get(b.id) ?? 0));
  } catch (e) {
    console.error("getBookmarkedJobs failed", e);
    return [];
  }
}

/**
 * The set of job ids the signed-in user has bookmarked. One query — pass the
 * set down to a list of cards so each can show its saved state without a
 * per-card round-trip. Empty for signed-out / offline.
 */
export async function getBookmarkedJobIds(): Promise<Set<string>> {
  if (!hasSupabase()) return new Set();
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return new Set();
    const { data, error } = await supabase
      .from("bookmarks")
      .select("job_id")
      .eq("profile_id", user.id);
    if (error) throw error;
    return new Set(
      (data ?? []).map((b) => String((b as { job_id: unknown }).job_id)),
    );
  } catch (e) {
    console.error("getBookmarkedJobIds failed", e);
    return new Set();
  }
}

/** Whether the signed-in user has bookmarked a job. */
export async function isBookmarked(jobId: string): Promise<boolean> {
  if (!hasSupabase()) return false;
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return false;
    const { data } = await supabase
      .from("bookmarks")
      .select("id")
      .eq("profile_id", user.id)
      .eq("job_id", jobId)
      .maybeSingle();
    return !!data;
  } catch {
    return false;
  }
}
