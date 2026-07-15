"use client";

import { useEffect } from "react";

import { track } from "@/lib/analytics/track";

/**
 * Fires a `track()` event once, on mount — the standard pattern for
 * "page X was viewed" from an RSC server component (which can't call
 * hooks directly). Render as `<PageEvent name="job_view" props={...}>`
 * inside the RSC and the event goes out client-side.
 *
 * Not tied to the router lifecycle: mounting once is right for the
 * "viewed this page" moment. If we later need per-nav pageviews (SPA
 * transitions), a Router-hooked helper is a separate concern from
 * this one.
 */
export function PageEvent({
  name,
  props,
}: {
  name:
    | "job_view"
    | "search_performed"
    | "signup_complete"
    | "vacancy_post_start"
    | "vacancy_post_complete"
    | "wallet_topup_pending"
    | "saved_search_created";
  props?: Record<string, string | number | boolean | null | undefined>;
}) {
  // Serialize once, outside the effect, so the deps array stays a single
  // stable string — otherwise re-mounting the parent re-fires the event.
  const key = JSON.stringify(props ?? null);
  useEffect(() => {
    track(name, props);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [name, key]);
  return null;
}
