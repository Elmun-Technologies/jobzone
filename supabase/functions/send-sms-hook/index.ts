// send-sms-hook — Supabase Auth "Send SMS" hook. Supabase's own phone-OTP
// system generates, stores, hashes, rate-limits and verifies the code
// end-to-end; this hook is called once per code and is responsible only for
// *delivering* it — here, via Telegram Gateway (gateway.telegram.org) instead
// of a traditional SMS provider, so a code is delivered as a Telegram message
// rather than an SMS. The client still calls supabase.auth.signInWithOtp({phone})
// to trigger a code and supabase.auth.verifyOtp({phone, token, type:'sms'}) to
// complete sign-in — Supabase mints the session itself; nothing here does.
//
// Configure in the Supabase Dashboard: Authentication -> Hooks -> Send SMS hook
// -> point it at this function's URL. Supabase then generates a signing secret
// (shown once, formatted like "v1,whsec_xxx") — set it as SEND_SMS_HOOK_SECRET.
// Required secrets: SEND_SMS_HOOK_SECRET, TELEGRAM_GATEWAY_TOKEN (from
// https://gateway.telegram.org — a separate product from a regular bot token).
//
// Payload verification follows the Standard Webhooks spec (the same scheme
// Supabase's other auth hooks use): headers webhook-id / webhook-timestamp /
// webhook-signature, HMAC-SHA256 over "<id>.<timestamp>.<raw body>".
//
// NOTE: the exact Telegram Gateway request/response field names below are
// implemented from the documented API (https://core.telegram.org/gateway/api)
// but have not been exercised against a live account from this environment —
// re-verify field names against the live docs before relying on this in
// production, and adjust if Telegram's response shape differs.

import { timingSafeEqual } from "../_shared/auth.ts";

interface HookPayload {
  user?: { phone?: string };
  sms?: { otp?: string };
}

function base64ToBytes(b64: string): Uint8Array<ArrayBuffer> {
  const bin = atob(b64);
  const out = new Uint8Array(new ArrayBuffer(bin.length));
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

function bytesToBase64(bytes: Uint8Array): string {
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin);
}

/** Verifies the Standard-Webhooks HMAC signature Supabase attaches to the call. */
async function verifySignature(req: Request, rawBody: string): Promise<boolean> {
  const secret = Deno.env.get("SEND_SMS_HOOK_SECRET");
  if (!secret) return false;

  const id = req.headers.get("webhook-id");
  const timestamp = req.headers.get("webhook-timestamp");
  const sigHeader = req.headers.get("webhook-signature");
  if (!id || !timestamp || !sigHeader) return false;

  // Reject stale/future timestamps to close the replay window (Standard-Webhooks
  // recommends a tolerance check; OTP messages are time-sensitive anyway).
  const ts = Number.parseInt(timestamp, 10);
  if (!Number.isFinite(ts) || Math.abs(Date.now() / 1000 - ts) > 300) {
    return false;
  }

  const secretB64 = secret.replace(/^v1,?\s*whsec_/, "");
  const key = await crypto.subtle.importKey(
    "raw",
    base64ToBytes(secretB64),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signedContent = `${id}.${timestamp}.${rawBody}`;
  const sigBytes = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(signedContent),
  );
  const expected = bytesToBase64(new Uint8Array(sigBytes));

  // The header can carry multiple "v1,<base64>" entries space-separated.
  return sigHeader
    .split(" ")
    .some((part) => timingSafeEqual(part.split(",")[1] ?? "", expected));
}

function hookError(httpCode: number, message: string) {
  return new Response(JSON.stringify({ error: { http_code: httpCode, message } }), {
    status: 200, // Auth hooks report failure in the body, not the HTTP status.
    headers: { "Content-Type": "application/json" },
  });
}

async function sendViaTelegramGateway(
  phone: string,
  code: string,
): Promise<{ ok: true } | { ok: false; message: string }> {
  const token = Deno.env.get("TELEGRAM_GATEWAY_TOKEN");
  if (!token) {
    return { ok: false, message: "Telegram Gateway is not configured" };
  }

  const headers = {
    Authorization: `Bearer ${token}`,
    "Content-Type": "application/json",
  };

  const ability = await fetch("https://gateway.telegram.org/checkSendAbility", {
    method: "POST",
    headers,
    body: JSON.stringify({ phone_number: phone }),
  }).then((r) => r.json()).catch(() => null);
  if (!ability?.ok) {
    return {
      ok: false,
      message: ability?.error ?? "Telegram Gateway declined this number",
    };
  }

  const send = await fetch("https://gateway.telegram.org/sendVerificationMessage", {
    method: "POST",
    headers,
    body: JSON.stringify({
      phone_number: phone,
      request_id: ability.result?.request_id,
      code, // Reuse Supabase's own OTP so verifyOtp() checks against it, not a
      // second code Telegram would otherwise generate itself.
    }),
  }).then((r) => r.json()).catch(() => null);
  if (!send?.ok) {
    return { ok: false, message: send?.error ?? "Telegram Gateway send failed" };
  }
  return { ok: true };
}

Deno.serve(async (req) => {
  const rawBody = await req.text();

  if (!(await verifySignature(req, rawBody))) {
    return hookError(401, "invalid webhook signature");
  }

  let payload: HookPayload;
  try {
    payload = JSON.parse(rawBody);
  } catch {
    return hookError(400, "invalid payload");
  }

  const phone = payload.user?.phone;
  const otp = payload.sms?.otp;
  if (!phone || !otp) {
    return hookError(400, "missing phone or otp in payload");
  }

  const result = await sendViaTelegramGateway(`+${phone}`, otp);
  if (!result.ok) return hookError(500, result.message);

  return new Response(JSON.stringify({}), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
