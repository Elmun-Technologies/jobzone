// sentry.edge.config.ts — Sentry init for the Edge runtime (Next
// middleware / Edge route handlers). Loaded by instrumentation.ts when
// NEXT_RUNTIME === 'edge'. Kept at the repo root per the Sentry wizard's
// convention.
//
// The Edge runtime is more restricted than Node.js (no fs, no
// long-running background tasks) so we opt out of the browser-only /
// Node-only integrations that ship in the default Sentry set.

import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.SENTRY_DSN ?? process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.VERCEL_ENV ?? process.env.NODE_ENV,
  tracesSampleRate: 0.1,
  sendDefaultPii: false,
  debug: process.env.NODE_ENV !== "production",
});
