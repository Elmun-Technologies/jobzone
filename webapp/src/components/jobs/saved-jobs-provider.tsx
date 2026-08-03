"use client";

import { createContext, useContext, useEffect, useState } from "react";

import { createClient } from "@/lib/supabase/client";

/** `null` until we know — a signed-out visitor settles on an empty set. */
const SavedJobsContext = createContext<Set<string> | null>(null);

/**
 * The seeker's saved vacancies, fetched in the browser instead of on the
 * server.
 *
 * Every public page used to call `getBookmarkedJobIds()` so the hearts could
 * render filled. That one per-visitor read is what kept those pages off the
 * CDN: a page that reads the session cannot be prerendered, no matter how
 * cacheable the rest of it is. Moving it here makes the pages themselves
 * identical for everyone — the hearts fill in a beat later, on the client,
 * which is the correct trade for a decoration on someone else's content.
 *
 * Reads `my_bookmarked_jobs` (0080), which is already scoped to `auth.uid()`,
 * so a signed-out visitor simply gets nothing back.
 */
export function SavedJobsProvider({ children }: { children: React.ReactNode }) {
  const [saved, setSaved] = useState<Set<string> | null>(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const supabase = createClient();
        const {
          data: { user },
        } = await supabase.auth.getUser();
        if (!user) {
          if (!cancelled) setSaved(new Set());
          return;
        }
        const { data } = await supabase.from("my_bookmarked_jobs").select("id");
        if (cancelled) return;
        setSaved(
          new Set((data ?? []).map((r) => String((r as { id: unknown }).id))),
        );
      } catch {
        // A failed read must not break the page — the hearts just stay empty.
        if (!cancelled) setSaved(new Set());
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <SavedJobsContext.Provider value={saved}>
      {children}
    </SavedJobsContext.Provider>
  );
}

/**
 * Whether this job is saved, or `null` while unknown. A caller with its own
 * server-rendered answer (the saved list, the account pages) keeps using that.
 */
export function useSavedJob(jobId: string): boolean | null {
  const saved = useContext(SavedJobsContext);
  return saved === null ? null : saved.has(jobId);
}
