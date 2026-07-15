// sentry.server.config.ts — Sentry init for the Node.js runtime (Server
// Components, route handlers, server actions). Loaded by instrumentation.ts
// when NEXT_RUNTIME === 'nodejs'. Kept at the repo root per the Sentry
// wizard's convention so a future `sentry-wizard` re-run recognises it.
//
// Gated on SENTRY_DSN (server-only) with a fallback to NEXT_PUBLIC_SENTRY_DSN
// so a single Vercel env can drive both the browser bundle and the server
// runtime. Empty → the init below no-ops via Sentry's own DSN check.

import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.SENTRY_DSN ?? process.env.NEXT_PUBLIC_SENTRY_DSN,
  // Same environment label Vercel uses on its deploys — "production",
  // "preview", or "development" — so filtering in Sentry lines up with
  // the Vercel dashboard without extra config.
  environment: process.env.VERCEL_ENV ?? process.env.NODE_ENV,
  // 10% of transactions traced by default — safe for launch traffic and
  // keeps the free-tier performance-event budget usable. Raise per-route
  // via `Sentry.startSpan` if a specific flow needs fuller coverage.
  tracesSampleRate: 0.1,
  // PII (IP address, user id, cookies) is off by default here — we only
  // want the stack + breadcrumbs, not the visitor's identity. Flip on
  // if you set `Sentry.setUser` explicitly in a route.
  sendDefaultPii: false,
  // Verbose Sentry logs only in development.
  debug: process.env.NODE_ENV !== "production",
});
