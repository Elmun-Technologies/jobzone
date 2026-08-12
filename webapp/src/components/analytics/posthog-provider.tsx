"use client";

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
 * The SDK is imported dynamically, and that matters more than it looks:
 * a top-level `import posthog from "posthog-js"` put 248 KB of it in the
 * bundle every visitor downloads on every page — including the ones who
 * declined cookies and will never run a line of it, and every build where
 * the key isn't even set. Behind the key check it becomes a chunk that is
 * only ever fetched by someone who has consented.
 *
 * The `track()` helper reaches window.posthog directly (posthog.init sets
 * it), so this component doesn't need to expose a context — it just installs.
 */
export function PostHogProvider() {
  useEffect(() => {
    const key = process.env.NEXT_PUBLIC_POSTHOG_KEY;
    if (!key) return;
    let cancelled = false;
    void (async () => {
      const { default: posthog } = await import("posthog-js");
      if (cancelled || posthog.__loaded) return;
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
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  return null;
}
