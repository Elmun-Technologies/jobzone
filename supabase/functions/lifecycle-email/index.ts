// lifecycle-email — the account-lifecycle mail: today, the welcome.
//
// Invoked by the two auth.users triggers from migration 0084 (pg_net POST):
//   • confirmations OFF → fired on INSERT, `trigger: 'signup'`
//   • confirmations ON  → fired when email_confirmed_at is first set,
//                         `trigger: 'confirmed'`
// so exactly one welcome goes out per account, whichever way the project is
// configured. `email_deliveries.dedupe_key = 'welcome:<uid>'` is the belt to
// that braces: a replayed trigger can never send a second copy.
//
// The mail itself is written in the recipient's language and branches on their
// role — a seeker is pointed at jobs and saved-search alerts, an employer at
// posting their first vacancy.
//
// Required secrets: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, EDGE_SHARED_SECRET
// Optional: RESEND_API_KEY + EMAIL_FROM (without them this is a logged no-op)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { corsHeaders, json } from "../_shared/cors.ts";
import { requireEdgeSecret } from "../_shared/auth.ts";
import {
  deliver,
  emailConfigured,
  linksFor,
  loadRecipient,
  logDelivery,
  looksLikeEmail,
} from "../_shared/email.ts";
import { welcomeEmail } from "../_shared/email-templates.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Invoked by a DB trigger. Fail closed.
  const denied = requireEdgeSecret(req);
  if (denied) return denied;

  const payload = await req.json().catch(() => ({}));
  const kind = String(payload?.kind ?? "welcome");
  const userId = payload?.user_id ? String(payload.user_id) : "";
  const triggeredBy = String(payload?.trigger ?? "signup");
  if (!userId) return json({ ok: false, error: "no user" }, 400);
  if (kind !== "welcome") return json({ ok: false, error: "unknown kind" }, 400);

  const supa = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const recipient = await loadRecipient(supa, userId);
  // The trigger passes the address it saw; profiles.email can lag behind it
  // (e.g. an address changed straight after signup).
  const email = recipient.email ??
    (looksLikeEmail(payload?.email) ? String(payload.email).trim() : null);
  if (!email) return json({ ok: true, skipped: "no address" });

  const dedupeKey = `welcome:${userId}`;

  if (!emailConfigured()) {
    // Record the gap instead of failing silently: "why didn't the welcome
    // arrive?" should be answerable from the send log alone. No dedupe key —
    // the real send must still be possible once the provider is configured.
    await logDelivery(supa, {
      recipientId: userId,
      to: email,
      kind: "welcome",
      locale: recipient.locale,
      subject: "welcome",
      status: "skipped",
      error: "email not configured",
    });
    return json({ ok: true, skipped: "not configured" });
  }

  const content = welcomeEmail(
    recipient.locale,
    {
      name: recipient.name,
      role: recipient.role,
      confirmed: triggeredBy === "confirmed",
    },
    linksFor(recipient.prefs.unsubscribe_token, recipient.locale),
  );

  const result = await deliver(supa, {
    recipient: { ...recipient, email },
    content,
    kind: "welcome",
    // Transactional: no category to opt out of, so no one-click header.
    scope: null,
    dedupeKey,
  });

  return json({ ok: result.status !== "failed", status: result.status });
});
