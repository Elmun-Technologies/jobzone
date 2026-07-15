import * as Sentry from "@sentry/nextjs";

/**
 * Client-runtime Sentry init. Next 15+ picks this file up automatically
 * for the browser bundle (mirror of instrumentation.ts on the server).
 * Kept inline (rather than dispatched to a sentry.client.config.ts)
 * because the client bundle is where dead-code elimination matters
 * most — the DSN check short-circuits the whole block when unset.
 *
 * Session Replay is opt-in via `replaysOnErrorSampleRate: 1.0` — every
 * session that hits an error is replayed, no replays for happy sessions.
 * That's the highest signal-to-noise trade-off for a job platform where
 * a full-session replay budget would burn through a free quota fast, and
 * where salary/CV inputs (masked below) are the most sensitive fields
 * you could accidentally capture.
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
    // Session Replay — 10% of ordinary sessions, 100% of sessions that
    // throw. Errored sessions are where replay pays off; a healthy
    // session's replay only fills the quota. Every input is masked and
    // every media asset blocked so a résumé draft / salary field never
    // leaves the browser.
    replaysSessionSampleRate: 0.1,
    replaysOnErrorSampleRate: 1.0,
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
    integrations: [
      Sentry.browserTracingIntegration(),
      Sentry.replayIntegration({
        maskAllInputs: true,
        maskAllText: false,
        blockAllMedia: true,
      }),
    ],
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
