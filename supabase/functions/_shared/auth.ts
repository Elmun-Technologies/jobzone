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

/**
 * Fail-CLOSED gate for the Telegram webhook. Telegram calls this with no
 * Supabase JWT, so its only authenticity check is the `secret_token` set on
 * `setWebhook` (https://core.telegram.org/bots/api#setwebhook), which
 * Telegram echoes back on every update as `X-Telegram-Bot-Api-Secret-Token`.
 * Without this, anyone who learns or guesses a live one-time link token
 * (telegram_link_tokens) could POST a forged update straight to this
 * function and bind their own chat to another user's profile.
 */
export function requireTelegramSecret(req: Request): Response | null {
  const secret = Deno.env.get("TELEGRAM_WEBHOOK_SECRET");
  if (!secret) {
    return json({ ok: false, error: "service not configured" }, 503);
  }
  const got = req.headers.get("x-telegram-bot-api-secret-token") ?? "";
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
