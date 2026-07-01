import { json } from "./cors.ts";

/**
 * Fail-CLOSED shared-secret gate for server-to-server edge functions (those run
 * with verify_jwt = false and invoked by DB triggers / cron). Returns a Response
 * to short-circuit the request, or null when the caller is authorized.
 *
 * - If EDGE_SHARED_SECRET is unset → 503 (refuse; never run unauthenticated).
 * - If the x-edge-secret header is missing or wrong → 401.
 *
 * The comparison is constant-time to avoid leaking the secret via timing.
 */
export function requireEdgeSecret(req: Request): Response | null {
  const secret = Deno.env.get("EDGE_SHARED_SECRET");
  if (!secret) {
    return json({ ok: false, error: "service not configured" }, 503);
  }
  const got = req.headers.get("x-edge-secret") ?? "";
  if (!timingSafeEqual(got, secret)) {
    return json({ ok: false, error: "unauthorized" }, 401);
  }
  return null;
}

/** Constant-time string comparison, exported for other secret/signature checks. */
export function timingSafeEqual(a: string, b: string): boolean {
  // Compare against a fixed length so a length mismatch doesn't early-return.
  let diff = a.length ^ b.length;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i % b.length);
  }
  return diff === 0;
}
