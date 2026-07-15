"use client";

import posthog from "posthog-js";
import { useEffect } from "react";

/**
 * PostHog client-side init — funnels, retention, session replay. Loaded
 * client-only (posthog-js runs in the browser); server events go through
 * the JS SDK separately if we add them later.
 *
 * Skeleton: bootstraps only when `NEXT_PUBLIC_POSTHOG_KEY` is set, so a
 * dev/preview build without the env is a no-op (no autocapture, no
 * network traffic). Autocapture is on by default — PostHog wires up
 * clicks/pageviews without extra code — with session replay opted in.
 *
 * The `track()` helper (below) reaches window.posthog directly, so this
 * component doesn't need to expose a context — it just installs.
 */
export function PostHogProvider() {
  useEffect(() => {
    const key = process.env.NEXT_PUBLIC_POSTHOG_KEY;
    if (!key) return;
    if (posthog.__loaded) return;
    posthog.init(key, {
      api_host:
        process.env.NEXT_PUBLIC_POSTHOG_HOST ?? "https://us.i.posthog.com",
      // Autocapture (all clicks / form submits) + built-in pageviews. Turn
      // pageview off if we ever add manual pageview tracking on route change.
      capture_pageview: true,
      capture_pageleave: true,
      autocapture: true,
      // Session replay — off by default; flip when you're ready to
      // review sessions (requires a plan check on volume).
      session_recording: {
        maskAllInputs: true,
      },
      // Respect Do Not Track — good default for a job platform where a
      // seeker's browsing pattern is sensitive (salary levels etc.).
      respect_dnt: true,
      // Cross-subdomain persistence for future www / employer subdomains.
      persistence: "localStorage+cookie",
    });
  }, []);

  return null;
}
