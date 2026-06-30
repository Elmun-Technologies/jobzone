// notify-dispatch — fans a freshly-inserted notification row out to the
// recipient's external channels: Telegram (when the user linked their chat via
// the /start handshake and TELEGRAM_BOT_TOKEN is set) and FCM push (when
// FCM_SERVICE_ACCOUNT is set and the user has registered devices). The in-app
// row already exists; this only mirrors it outward, and it respects the
// recipient's notification_settings.
//
// Invoked by the `notifications` AFTER-INSERT pg_net trigger (migration 0026)
// with body { type:'INSERT', table:'notifications', record:{...} }.
//
// Required secrets: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
// Optional: TELEGRAM_BOT_TOKEN, FCM_SERVICE_ACCOUNT (each enables its channel),
//           EDGE_SHARED_SECRET (gate)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { corsHeaders, json } from "../_shared/cors.ts";
import { sendFcmToUser } from "../_shared/fcm.ts";
import { requireEdgeSecret } from "../_shared/auth.ts";

// Maps a notification type to its notification_settings push column. Types with
// no column (e.g. 'system') are always delivered.
const PUSH_COL: Record<string, string> = {
  message: "push_messages",
  application_update: "push_application",
  job_match: "push_job_match",
  review: "push_reviews",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Invoked by the notifications AFTER-INSERT pg_net trigger. Fail closed.
  const denied = requireEdgeSecret(req);
  if (denied) return denied;

  const payload = await req.json().catch(() => ({}));
  const rec = payload?.record ?? payload;
  const recipientId = rec?.recipient_id;
  const type = String(rec?.type ?? "system");
  const title = String(rec?.title ?? "Jobzone");
  const body = String(rec?.body ?? "");
  if (!recipientId) return json({ ok: false, error: "no recipient" }, 400);

  const supa = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Respect the recipient's per-category push preference.
  const col = PUSH_COL[type];
  if (col) {
    const { data: settings } = await supa
      .from("notification_settings")
      .select(col)
      .eq("profile_id", recipientId)
      .maybeSingle();
    if (settings && (settings as Record<string, unknown>)[col] === false) {
      return json({ ok: true, skipped: "muted" });
    }
  }

  // Telegram fan-out (no-op without a bot token or a linked chat).
  let telegram = 0;
  const botToken = Deno.env.get("TELEGRAM_BOT_TOKEN");
  if (botToken) {
    const { data: link } = await supa
      .from("telegram_links")
      .select("telegram_chat_id")
      .eq("profile_id", recipientId)
      .maybeSingle();
    if (link?.telegram_chat_id) {
      const text = body ? `*${title}*\n${body}` : `*${title}*`;
      const r = await fetch(
        `https://api.telegram.org/bot${botToken}/sendMessage`,
        {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify({
            chat_id: link.telegram_chat_id,
            text,
            parse_mode: "Markdown",
          }),
        },
      ).catch(() => null);
      if (r && r.ok) telegram = 1;
    }
  }

  // Push fan-out (no-op without FCM_SERVICE_ACCOUNT or registered devices).
  // Include the notification type so the client can deep-link to the right screen.
  const fcm = await sendFcmToUser(
    supa,
    recipientId,
    title,
    body,
    { type, ...(rec?.data ?? {}) } as Record<string, unknown>,
  );

  return json({ ok: true, telegram, fcm });
});
