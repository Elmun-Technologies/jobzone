// _shared/fcm.ts — Firebase Cloud Messaging HTTP v1 sender.
//
// Sends a push to every device a recipient has registered (the `devices` table,
// migration 0008). Mints a Google OAuth2 access token from the
// FCM_SERVICE_ACCOUNT JSON secret (an RS256 JWT signed via Web Crypto), caches
// it until ~expiry, then POSTs to the FCM v1 endpoint per token. Tokens FCM
// reports as UNREGISTERED (HTTP 404) are pruned from `devices`.
//
// No-op (returns 0) when FCM_SERVICE_ACCOUNT is unset, so callers degrade
// gracefully and local `supabase db reset` / CI stay clean.

import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
  token_uri?: string;
}

let _sa: ServiceAccount | null | undefined;
function serviceAccount(): ServiceAccount | null {
  if (_sa !== undefined) return _sa;
  const raw = Deno.env.get("FCM_SERVICE_ACCOUNT");
  if (!raw) return (_sa = null);
  try {
    _sa = JSON.parse(raw) as ServiceAccount;
  } catch {
    console.error("FCM_SERVICE_ACCOUNT is not valid JSON");
    _sa = null;
  }
  return _sa;
}

function b64url(data: Uint8Array | string): string {
  const bytes = typeof data === "string"
    ? new TextEncoder().encode(data)
    : data;
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToPkcs8(pem: string): Uint8Array {
  const body = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const bin = atob(body);
  const buf = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) buf[i] = bin.charCodeAt(i);
  return buf;
}

let _token: { value: string; exp: number } | null = null;

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (_token && _token.exp - 60 > now) return _token.value;

  const tokenUri = sa.token_uri ?? "https://oauth2.googleapis.com/token";
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: tokenUri,
    iat: now,
    exp: now + 3600,
  }));
  const signingInput = `${header}.${claims}`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToPkcs8(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = new Uint8Array(
    await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      key,
      new TextEncoder().encode(signingInput),
    ),
  );
  const jwt = `${signingInput}.${b64url(sig)}`;

  const res = await fetch(tokenUri, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) throw new Error(`oauth ${res.status}: ${await res.text()}`);
  const data = await res.json();
  _token = {
    value: data.access_token as string,
    exp: now + (Number(data.expires_in) || 3600),
  };
  return _token.value;
}

/**
 * Sends a push to all of the recipient's devices. Returns the count delivered.
 * No-op (0) when FCM isn't configured or the user has no registered devices.
 */
export async function sendFcmToUser(
  supa: SupabaseClient,
  recipientId: string,
  title: string,
  body: string,
  data: Record<string, unknown> = {},
): Promise<number> {
  const sa = serviceAccount();
  if (!sa) return 0;

  const { data: devices } = await supa
    .from("devices")
    .select("fcm_token")
    .eq("profile_id", recipientId);
  const tokens = (devices ?? []).map((d: { fcm_token: string }) => d.fcm_token);
  if (tokens.length === 0) return 0;

  let accessToken: string;
  try {
    accessToken = await getAccessToken(sa);
  } catch (e) {
    console.error("FCM token mint failed:", e);
    return 0;
  }

  // FCM v1 `data` must be a string→string map.
  const stringData: Record<string, string> = {};
  for (const [k, v] of Object.entries(data)) stringData[k] = String(v);

  const url =
    `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;
  let sent = 0;
  const stale: string[] = [];
  for (const token of tokens) {
    const r = await fetch(url, {
      method: "POST",
      headers: {
        authorization: `Bearer ${accessToken}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        message: { token, notification: { title, body }, data: stringData },
      }),
    }).catch(() => null);
    if (r && r.ok) {
      sent++;
    } else if (r && r.status === 404) {
      // UNREGISTERED — the app was uninstalled or the token rotated. Prune it.
      stale.push(token);
    }
  }
  if (stale.length) {
    await supa.from("devices").delete().in("fcm_token", stale);
  }
  return sent;
}
