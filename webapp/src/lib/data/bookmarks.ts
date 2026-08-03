import "server-only";

import { createClient } from "@/lib/supabase/server";

import { toJob } from "./mappers";
import { hasSupabase } from "./supabase-env";
import type { Job } from "./types";

/**
 * Minimal Job stand-ins for saved vacancies no longer in `job_feed`, read from
 * the `my_bookmarked_jobs` definer view (0080). Only what the card renders.
 */
async function closedBookmarks(
  supabase: Awaited<ReturnType<typeof createClient>>,
  ids: string[],
): Promise<Job[]> {
  try {
    const { data, error } = await supabase
      .from("my_bookmarked_jobs")
      .select("id, title, status, company_name")
      .in("id", ids);
    if (error) throw error;
    return (data ?? []).map((r) => {
      const row = r as Record<string, unknown>;
      return toJob({
        id: row.id,
        title: row.title,
        status: row.status ?? "closed",
        company_name: row.company_name,
      });
    });
  } catch (e) {
    // A database behind on 0080 has no such view. Degrade to the old
    // behaviour (the row is dropped) rather than failing the whole list.
    console.error("closedBookmarks failed", e);
    return [];
  }
}

/** The signed-in user's bookmarked jobs, newest-saved first — including any
 * that have since closed, which are marked rather than dropped. */
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

    const live = (rows ?? []).map(toJob);
    // Whatever job_feed withheld is a vacancy that has left the market — it
    // only shows non-owners status='open'. Dropping those made a saved job
    // silently disappear while its bookmark row sat in the database; the
    // definer view (0080) carries just enough to keep the record on screen,
    // marked closed, exactly as the applications list has since 0048.
    const missing = ids.filter((id) => !live.some((j) => j.id === id));
    const closed = missing.length
      ? await closedBookmarks(supabase, missing)
      : [];

    // Preserve bookmark (most-recent-first) order across both sources.
    const byId = new Map([...live, ...closed].map((j) => [j.id, j]));
    return ids.map((id) => byId.get(id)).filter((j): j is Job => Boolean(j));
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

/**
 * Jobs the seeker archived ("not interested"). They are filtered out of every
 * feed, which made archiving irreversible in practice: the card carrying the
 * "tap to restore" affordance was exactly the card that had been hidden. This
 * is the one surface that can show them again.
 *
 * Reads `job_feed`, so a job that has since closed or expired drops out on its
 * own — there is nothing to restore it to.
 */
export async function getArchivedJobs(): Promise<Job[]> {
  if (!hasSupabase()) return [];
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return [];

    const { data: rowsIds, error } = await supabase
      .from("dismissed_jobs")
      .select("job_id, created_at")
      .eq("profile_id", user.id)
      .order("created_at", { ascending: false });
    if (error) throw error;

    const ids = (rowsIds ?? []).map((b) =>
      String((b as { job_id: unknown }).job_id),
    );
    if (ids.length === 0) return [];

    const { data: rows, error: jobsError } = await supabase
      .from("job_feed")
      .select("*")
      .eq("status", "open")
      .in("id", ids);
    if (jobsError) throw jobsError;

    const order = new Map(ids.map((id, i) => [id, i]));
    return (rows ?? [])
      .map(toJob)
      .sort((a, b) => (order.get(a.id) ?? 0) - (order.get(b.id) ?? 0));
  } catch (e) {
    console.error("getArchivedJobs failed", e);
    return [];
  }
}
