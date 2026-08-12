// notify-dispatch — fans a freshly-inserted notification row out to the
// recipient's external channels: Telegram (when the user linked their chat via
// the /start handshake and TELEGRAM_BOT_TOKEN is set), FCM push (when
// FCM_SERVICE_ACCOUNT is set and the user has registered devices) and email
// (when RESEND_API_KEY is set). The in-app row already exists; this only
// mirrors it outward, and it respects the recipient's notification_settings —
// push_* per channel, email_* per category.
//
// Invoked by the `notifications` AFTER-INSERT pg_net trigger (migration 0026)
// with body { type:'INSERT', table:'notifications', record:{...} }.
//
// Required secrets: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
// Optional: TELEGRAM_BOT_TOKEN, FCM_SERVICE_ACCOUNT, RESEND_API_KEY + EMAIL_FROM
//           (each enables its channel), EDGE_SHARED_SECRET (gate)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { corsHeaders, json } from "../_shared/cors.ts";
import { sendFcmToUser } from "../_shared/fcm.ts";
import { requireEdgeSecret } from "../_shared/auth.ts";
import {
  type InviteJob,
  localizedNotificationText,
} from "../_shared/notification-text.ts";
import {
  deliver,
  emailConfigured,
  linksFor,
  loadRecipient,
  type Recipient,
  siteBase,
} from "../_shared/email.ts";
import {
  type EmailContent,
  type Loc,
  type NotificationEmailKind,
  notificationEmail,
} from "../_shared/email-templates.ts";

// Maps a notification type to its notification_settings push column. Types with
// no column (e.g. 'system') are always delivered.
const PUSH_COL: Record<string, string> = {
  message: "push_messages",
  application_update: "push_application",
  job_match: "push_job_match",
  review: "push_reviews",
};

// Which email category (notification_settings column + unsubscribe scope) a
// notification belongs to. `null` means "this type never travels by email".
function emailKindFor(
  type: string,
  data: Record<string, unknown>,
): NotificationEmailKind | null {
  switch (type) {
    case "message":
      return "message";
    case "application_update":
      return "application_update";
    case "job_match":
      // Saved-search / followed-company alerts are owned by the digest mailer
      // in `saved-search-alerts` — one grouped email per run beats one email
      // per vacancy, and sending both would double-mail every match.
      if (data.alert === true) return null;
      return "invite";
    case "review":
      return "review";
    case "system":
      // Only an explicitly email-enabled broadcast (admin_broadcast's
      // p_send_email) becomes marketing mail; ordinary system notices stay
      // in-app.
      return data.email === true ? "marketing" : null;
    default:
      return null;
  }
}

const EMAIL_PREF_COL: Record<NotificationEmailKind, keyof Recipient["prefs"]> = {
  message: "email_messages",
  application_update: "email_application",
  invite: "email_job_match",
  review: "email_reviews",
  marketing: "email_marketing",
};

const EMAIL_SCOPE: Record<NotificationEmailKind, string> = {
  message: "messages",
  application_update: "application",
  invite: "job_match",
  review: "reviews",
  marketing: "marketing",
};

/** Absolute deep link for an email CTA — mirrors the web client's
 *  notificationHref(), which is what the in-app rows link to. */
function deepLink(
  type: string,
  data: Record<string, unknown>,
  locale: Loc,
): string {
  const base = `${siteBase()}/${locale}`;
  const str = (k: string): string | null => {
    const v = data[k];
    return typeof v === "string" && v ? v : null;
  };
  if (type === "job_match") {
    const id = str("job_id");
    return id ? `${base}/jobs/${encodeURIComponent(id)}` : base;
  }
  if (type === "message") {
    const id = str("conversation_id");
    return id
      ? `${base}/account/messages/${encodeURIComponent(id)}`
      : `${base}/account/messages`;
  }
  if (type === "application_update") return `${base}/account/applications`;
  return base;
}

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

  const data = (rec?.data ?? {}) as Record<string, unknown>;

  // Respect the recipient's per-category push preference. This mutes the
  // instant channels (Telegram + push) only — email has its own switches
  // (email_*), so a user who turned push off still gets the digest they asked
  // for, and vice versa.
  const col = PUSH_COL[type];
  let pushMuted = false;
  if (col) {
    const { data: settings } = await supa
      .from("notification_settings")
      .select(col)
      .eq("profile_id", recipientId)
      .maybeSingle();
    pushMuted = Boolean(
      settings && (settings as Record<string, unknown>)[col] === false,
    );
  }

  // Does this row travel by email at all, and to whom?
  const emailKind = emailKindFor(type, data);
  const wantsEmail = emailKind !== null && emailConfigured();
  if (pushMuted && !wantsEmail) return json({ ok: true, skipped: "muted" });

  // Render in the recipient's language before anything leaves the building.
  // The in-app clients re-derive this text themselves because the triggers
  // store a fixed-language string (0005 writes English, invite_candidate()
  // writes Uzbek); Telegram, push and email have no client to do that, so
  // without this step every outward message ignores the language the user
  // picked.
  const recipient = await loadRecipient(supa, recipientId, {
    resolveEmail: wantsEmail,
  });

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
    recipient.locale,
    type,
    title,
    body,
    data,
    invite,
  );

  // Telegram fan-out (no-op without a bot token or a linked chat).
  let telegram = 0;
  const botToken = pushMuted ? null : Deno.env.get("TELEGRAM_BOT_TOKEN");
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
  const fcm = pushMuted ? 0 : await sendFcmToUser(
    supa,
    recipientId,
    text.title,
    text.body,
    { type, ...data },
  );

  // Email fan-out (no-op without RESEND_API_KEY, an address, or the recipient's
  // consent for this category).
  let email = "skipped";
  if (emailKind && wantsEmail) {
    const allowed = recipient.prefs[EMAIL_PREF_COL[emailKind]] !== false;
    if (!allowed) {
      email = "muted";
    } else if (!recipient.email) {
      email = "no_address";
    } else {
      const content: EmailContent = notificationEmail(
        recipient.locale,
        emailKind,
        {
          type,
          title,
          body,
          data,
          invite,
          url: deepLink(type, data, recipient.locale),
        },
        linksFor(recipient.prefs.unsubscribe_token, recipient.locale),
      );
      const result = await deliver(supa, {
        recipient,
        content,
        kind: emailKind,
        scope: EMAIL_SCOPE[emailKind],
        // One email per notification row: a retried trigger delivery (pg_net
        // can re-POST) must not mail the same thing twice.
        dedupeKey: rec?.id ? `notification:${rec.id}` : null,
      });
      email = result.status;
    }
  }

  return json({ ok: true, telegram, fcm, email });
});
