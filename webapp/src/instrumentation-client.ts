import * as Sentry from "@sentry/nextjs";

/**
 * Client-runtime Sentry init. Next 15+ picks this file up automatically
 * for the browser bundle (mirror of instrumentation.ts on the server).
 * Kept inline (rather than dispatched to a sentry.client.config.ts)
 * because the client bundle is where dead-code elimination matters
 * most — the DSN check short-circuits the whole block when unset.
 *
 * **Session Replay is intentionally NOT included.** The replay integration
 * ships ~85 KB of gzipped worker code and starts recording DOM mutations
 * on page load — the largest single contributor to Yolla's tunable JS
 * bundle, and enough to push LCP up on hot pages like /jobs. Yandex
 * Metrica already runs `webvisor` (its own session replay) so a second
 * recorder is redundant anyway. Bring it back per-route via
 * `Sentry.lazyLoadIntegration("replay")` inside a debug flow when you
 * actually need to review a session.
 */
const dsn = process.env.NEXT_PUBLIC_SENTRY_DSN;

if (dsn) {
  Sentry.init({
    dsn,
    // Same shape as the server config — Vercel's env label lines up with
    // Sentry's environment dimension.
    environment: process.env.NEXT_PUBLIC_VERCEL_ENV ?? "production",
    // 10% of transactions traced — matches server config for a coherent
    // front-to-back sampling rate. Raise per-route via startSpan if
    // a specific flow needs fuller coverage.
    tracesSampleRate: 0.1,
    // PII (IP, cookies, user identity) stays off unless a route calls
    // Sentry.setUser explicitly.
    sendDefaultPii: false,
    // Ignore benign errors that clog the inbox: extension-injected
    // scripts, canceled navigations, ResizeObserver loop noise.
    ignoreErrors: [
      "ResizeObserver loop limit exceeded",
      "ResizeObserver loop completed with undelivered notifications",
      "AbortError",
      "Non-Error promise rejection captured",
    ],
    integrations: [Sentry.browserTracingIntegration()],
  });
}

/**
 * Next 15+ hooks router transitions through this export so Sentry can
 * attach them as spans. Exported even when the SDK is dark so Next
 * doesn't warn about the missing symbol.
 */
export const onRouterTransitionStart = dsn
  ? Sentry.captureRouterTransitionStart
  : undefined;
