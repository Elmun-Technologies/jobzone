import * as Sentry from "@sentry/nextjs";

/**
 * Next 15+ picks this up automatically on every runtime it boots. Per the
 * Sentry Next.js SDK convention, this file just dispatches to the
 * runtime-specific config file at the repo root:
 *
 *   Node.js (Server Components / route handlers / actions)  → sentry.server.config.ts
 *   Edge   (middleware / edge route handlers)               → sentry.edge.config.ts
 *   Browser                                                 → instrumentation-client.ts (wired separately by Next)
 *
 * Keeping the actual Sentry.init in the wizard-style root files makes a
 * future `sentry-wizard` re-run idempotent, and lets the two runtimes
 * carry per-runtime integrations without cross-import.
 *
 * `dynamic()` (not a top-level import) keeps the Node-only code out of the
 * Edge bundle — Sentry's Node integrations pull node:async_hooks and
 * friends that aren't available in the Edge runtime, so importing
 * unconditionally would break the middleware build.
 */
export async function register() {
  if (process.env.NEXT_RUNTIME === "nodejs") {
    await import("../sentry.server.config");
  } else if (process.env.NEXT_RUNTIME === "edge") {
    await import("../sentry.edge.config");
  }
}

/**
 * Server-side error hook Next 15+ calls when a Server Component / route
 * handler throws. Sentry ships a ready-made handler that captures the
 * error along with the request context — safe to export unconditionally;
 * it no-ops when the SDK didn't init (DSN unset).
 */
export const onRequestError = Sentry.captureRequestError;
