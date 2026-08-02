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
import {
  type InviteJob,
  localizedNotificationText,
  normalizeLocale,
} from "../_shared/notification-text.ts";

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
  const title = String(rec?.title ?? "Yollla");
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

  // Render in the recipient's language before anything leaves the building.
  // The in-app clients re-derive this text themselves because the triggers
  // store a fixed-language string (0005 writes English, invite_candidate()
  // writes Uzbek); Telegram and push have no client to do that, so without
  // this step every outward message ignores the language the user picked.
  const data = (rec?.data ?? {}) as Record<string, unknown>;
  const { data: profile } = await supa
    .from("profiles")
    .select("preferred_locale")
    .eq("id", recipientId)
    .maybeSingle();

  // An invitation (0050) stores only `job_id`, so the company and role have to
  // be fetched to say it in any language other than the one it was written in.
  let invite: InviteJob | null = null;
  if (type === "job_match" && data.invited === true && data.job_id) {
    const { data: job } = await supa
      .from("jobs")
      .select("title, companies(name)")
      .eq("id", data.job_id)
      .maybeSingle();
    const company = (job?.companies as { name?: string } | null)?.name;
    if (job?.title && company) invite = { company, title: job.title };
  }

  const text = localizedNotificationText(
    normalizeLocale(profile?.preferred_locale),
    type,
    title,
    body,
    data,
    invite,
  );

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
      const message = text.body
        ? `*${text.title}*\n${text.body}`
        : `*${text.title}*`;
      const r = await fetch(
        `https://api.telegram.org/bot${botToken}/sendMessage`,
        {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify({
            chat_id: link.telegram_chat_id,
            text: message,
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
    text.title,
    text.body,
    { type, ...data },
  );

  return json({ ok: true, telegram, fcm });
});
