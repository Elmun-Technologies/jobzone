import * as Sentry from "@sentry/nextjs";

/**
 * Client-runtime Sentry init. Next 15+ picks this up automatically
 * (mirror of instrumentation.ts for the browser bundle).
 *
 * Gated on NEXT_PUBLIC_SENTRY_DSN — the browser needs the DSN in the
 * bundle to send events, so it MUST be `NEXT_PUBLIC_*`. Empty → skip.
 *
 * BrowserTracing is on for real-user perf spans (route change latency,
 * external fetches). Session replay is off until we're ready to review
 * sessions — flip via replayIntegration({ maskAllInputs: true }) when
 * you add it, so salary/CV fields never leak into replay frames.
 */
const dsn = process.env.NEXT_PUBLIC_SENTRY_DSN;

if (dsn) {
  Sentry.init({
    dsn,
    environment: process.env.NEXT_PUBLIC_VERCEL_ENV ?? "production",
    tracesSampleRate: 0.2,
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

// Next 15+ hooks router transitions through this export to attach
// them as Sentry spans — export it even when Sentry is dark so Next
// doesn't warn about the missing symbol.
export const onRouterTransitionStart = dsn
  ? Sentry.captureRouterTransitionStart
  : undefined;
