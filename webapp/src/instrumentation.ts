import * as Sentry from "@sentry/nextjs";

/**
 * Server + edge runtime initialisation. Next runs this once at boot on
 * every runtime the app has (Node.js for Server Components / route
 * handlers, Vercel Edge for the middleware). Client init lives in
 * `instrumentation-client.ts` — Next wires it separately.
 *
 * Everything gates on SENTRY_DSN. Empty → no init, no network, no
 * telemetry: safe to ship dark until we point it at a Sentry project.
 */
export function register() {
  const dsn = process.env.SENTRY_DSN ?? process.env.NEXT_PUBLIC_SENTRY_DSN;
  if (!dsn) return;

  const shared = {
    dsn,
    environment: process.env.VERCEL_ENV ?? process.env.NODE_ENV,
    // Sample everything at launch; drop this once traffic climbs so we
    // don't burn the quota (Sentry free tier: 5 000 errors / month,
    // 10 000 performance events).
    tracesSampleRate: 1.0,
    // Log Sentry init in server logs so a silent gate-fail is visible.
    debug: false,
  };

  if (process.env.NEXT_RUNTIME === "nodejs") {
    Sentry.init(shared);
  } else if (process.env.NEXT_RUNTIME === "edge") {
    Sentry.init(shared);
  }
}

export const onRequestError = Sentry.captureRequestError;
