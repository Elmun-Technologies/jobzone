/**
 * Next 15+ picks this up automatically on every runtime it boots.
 *
 *   Node.js (Server Components / route handlers / actions)  → sentry.server.config.ts
 *   Edge   (middleware / edge route handlers)               → intentionally NOT instrumented
 *   Browser                                                 → instrumentation-client.ts (wired separately by Next)
 *
 * ⚠️ The Edge runtime is deliberately left OUT of Sentry. Importing
 * `@sentry/nextjs` at module scope — even only for `onRequestError` — pulls
 * the Sentry Edge SDK, and with it `@opentelemetry/*`, into the `proxy.ts`
 * middleware bundle. That OpenTelemetry code fails to invoke on Vercel's
 * Edge runtime, so EVERY request through the middleware 500s with
 * `MIDDLEWARE_INVOCATION_FAILED` — a total outage of a guest-first site.
 * So: no top-level Sentry import here, no edge-config import, and the edge
 * branch of register() is a no-op. Sentry still covers the two runtimes
 * that matter — the browser (client errors) and the Node server (SSR /
 * route handlers / actions).
 */
export async function register() {
  if (process.env.NEXT_RUNTIME === "nodejs") {
    await import("../sentry.server.config");
  }
  // Edge runtime: intentionally no Sentry (see file header).
}

/**
 * Server-side error hook Next calls when a Server Component / route handler
 * throws. Import Sentry LAZILY and only in the Node runtime, so the symbol
 * (and its OTel dependencies) never lands in the Edge middleware bundle.
 * No-ops on the Edge runtime and when the SDK didn't init.
 */
export async function onRequestError(
  ...args: Parameters<typeof import("@sentry/nextjs").captureRequestError>
): Promise<void> {
  if (process.env.NEXT_RUNTIME !== "nodejs") return;
  const Sentry = await import("@sentry/nextjs");
  Sentry.captureRequestError(...args);
}
