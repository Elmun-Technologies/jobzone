// _shared/email.ts — the outbound email channel.
//
// One HTTP sender (Resend's API, or anything that speaks the same shape via
// EMAIL_API_BASE) plus the bookkeeping every send needs: who the recipient is,
// which language they read, whether they've opted out of this category, and a
// row in `email_deliveries` (0084) recording what happened.
//
// No-op — not a crash — when RESEND_API_KEY is unset, exactly like the FCM and
// Telegram channels: the platform must keep working before the mail domain is
// live, and the send log records the skip so the gap is visible.
//
// Secrets:
//   RESEND_API_KEY   enables the channel
//   EMAIL_FROM       "Yolla <bildirishnoma@yollla.uz>"  (must be a verified domain)
//   EMAIL_REPLY_TO   optional, e.g. "yordam@yollla.uz"
//   EMAIL_API_BASE   optional override (default https://api.resend.com)
//   WEBAPP_URL       link base for every CTA (default https://www.yollla.uz)

import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import {
  type EmailContent,
  type EmailLinks,
  type Loc,
  normalizeLocale,
} from "./email-templates.ts";

const DEFAULT_SITE = "https://www.yollla.uz";
const DEFAULT_FROM = "Yolla <noreply@yollla.uz>";

export type DeliveryStatus = "sent" | "failed" | "skipped";

export interface SendResult {
  status: DeliveryStatus;
  id?: string;
  error?: string;
}

/** True when a real provider key is present. */
export function emailConfigured(): boolean {
  return Boolean(Deno.env.get("RESEND_API_KEY"));
}

/** Site origin for every link in an email, without a trailing slash. */
export function siteBase(): string {
  return (Deno.env.get("WEBAPP_URL") ?? DEFAULT_SITE).replace(/\/+$/, "");
}

/** Deliberately permissive — the provider is the real validator; this only
 *  keeps obviously-empty or malformed rows out of the send queue. */
export function looksLikeEmail(value: unknown): boolean {
  const v = String(value ?? "").trim();
  return v.length > 3 && v.length <= 254 && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);
}

/** Human-facing unsubscribe page (works signed out — the token is the key). */
export function unsubscribeUrl(token: string | null, locale: Loc): string | null {
  if (!token) return null;
  return `${siteBase()}/${locale}/unsubscribe?token=${encodeURIComponent(token)}`;
}

/** RFC 8058 one-click endpoint (POST). Mail clients call this directly. */
export function oneClickUrl(
  token: string | null,
  scope: string | null,
): string | null {
  if (!token) return null;
  const scopeParam = scope ? `&scope=${encodeURIComponent(scope)}` : "";
  return `${siteBase()}/api/unsubscribe?token=${
    encodeURIComponent(token)
  }${scopeParam}`;
}

export function linksFor(token: string | null, locale: Loc): EmailLinks {
  return {
    site: siteBase(),
    unsubscribeUrl: unsubscribeUrl(token, locale) ?? undefined,
    prefsUrl: `${siteBase()}/${locale}/account/settings`,
  };
}

export interface SendEmailInput {
  to: string;
  content: EmailContent;
  /** Feeds List-Unsubscribe; both the page and the one-click endpoint. */
  unsubscribeUrl?: string | null;
  oneClickUrl?: string | null;
  /** Provider-side grouping (Resend tags), e.g. "job_alert". */
  tag?: string;
}

/**
 * Sends one email. Retries once on a rate-limit / 5xx (the provider's own
 * transient failures), then gives up — the caller logs the outcome and the
 * next alert run will try again.
 */
export async function sendEmail(input: SendEmailInput): Promise<SendResult> {
  const key = Deno.env.get("RESEND_API_KEY");
  if (!key) return { status: "skipped", error: "email not configured" };
  if (!looksLikeEmail(input.to)) {
    return { status: "skipped", error: "invalid address" };
  }

  const base = (Deno.env.get("EMAIL_API_BASE") ?? "https://api.resend.com")
    .replace(/\/+$/, "");
  const from = Deno.env.get("EMAIL_FROM") ?? DEFAULT_FROM;
  const replyTo = Deno.env.get("EMAIL_REPLY_TO");

  const headers: Record<string, string> = {};
  // Gmail/Yahoo bulk-sender rules: a working List-Unsubscribe (and the
  // one-click POST variant) is the difference between the inbox and spam.
  const listUnsub = [
    input.oneClickUrl ? `<${input.oneClickUrl}>` : null,
    input.unsubscribeUrl ? `<${input.unsubscribeUrl}>` : null,
  ].filter(Boolean).join(", ");
  if (listUnsub) {
    headers["List-Unsubscribe"] = listUnsub;
    if (input.oneClickUrl) {
      headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click";
    }
  }

  const body = JSON.stringify({
    from,
    to: [input.to],
    subject: input.content.subject,
    html: input.content.html,
    text: input.content.text,
    ...(replyTo ? { reply_to: replyTo } : {}),
    ...(Object.keys(headers).length ? { headers } : {}),
    ...(input.tag ? { tags: [{ name: "kind", value: input.tag }] } : {}),
  });

  for (let attempt = 0; attempt < 2; attempt++) {
    try {
      const res = await fetch(`${base}/emails`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${key}`,
          "Content-Type": "application/json",
        },
        body,
      });
      if (res.ok) {
        const payload = await res.json().catch(() => ({}));
        return { status: "sent", id: payload?.id ? String(payload.id) : undefined };
      }
      const detail = (await res.text().catch(() => "")).slice(0, 300);
      const retryable = res.status === 429 || res.status >= 500;
      if (!retryable || attempt === 1) {
        return { status: "failed", error: `${res.status} ${detail}` };
      }
      await new Promise((r) => setTimeout(r, 700));
    } catch (e) {
      if (attempt === 1) {
        return { status: "failed", error: String(e).slice(0, 300) };
      }
      await new Promise((r) => setTimeout(r, 700));
    }
  }
  return { status: "failed", error: "unreachable" };
}

// ---------------------------------------------------------------------------
// Recipient context + send log
// ---------------------------------------------------------------------------

export interface EmailPrefs {
  email_messages: boolean;
  email_application: boolean;
  email_job_match: boolean;
  email_reviews: boolean;
  email_marketing: boolean;
  unsubscribe_token: string | null;
}

export interface Recipient {
  id: string;
  email: string | null;
  locale: Loc;
  name: string | null;
  role: string | null;
  prefs: EmailPrefs;
}

const DEFAULT_PREFS: EmailPrefs = {
  email_messages: false,
  email_application: true,
  email_job_match: true,
  email_reviews: false,
  email_marketing: true,
  unsubscribe_token: null,
};

/**
 * Everything a send needs about one person. The address comes from
 * `profiles.email`, which handle_new_user() stamps at signup; when it is empty
 * (an older row, or a profile created before the column was populated) we ask
 * the auth admin API, which is the source of truth.
 */
export async function loadRecipient(
  supa: SupabaseClient,
  profileId: string,
  // Callers that only need the locale/prefs (a push-only fan-out) pass false
  // to skip the auth-admin lookup the address fallback would cost.
  opts: { resolveEmail?: boolean } = {},
): Promise<Recipient> {
  const resolveEmail = opts.resolveEmail ?? true;
  const [{ data: profile }, { data: prefs }] = await Promise.all([
    supa
      .from("profiles")
      .select("email, full_name, preferred_locale, role")
      .eq("id", profileId)
      .maybeSingle(),
    supa
      .from("notification_settings")
      .select(
        "email_messages, email_application, email_job_match, email_reviews, email_marketing, unsubscribe_token",
      )
      .eq("profile_id", profileId)
      .maybeSingle(),
  ]);

  let email = profile?.email as string | null | undefined;
  if (resolveEmail && !looksLikeEmail(email)) {
    const { data } = await supa.auth.admin.getUserById(profileId).catch(() => ({
      data: null,
    })) as { data: { user?: { email?: string | null } } | null };
    email = data?.user?.email ?? null;
  }

  return {
    id: profileId,
    email: looksLikeEmail(email) ? String(email).trim() : null,
    locale: normalizeLocale(profile?.preferred_locale),
    name: (profile?.full_name as string | null) ?? null,
    role: (profile?.role as string | null) ?? null,
    prefs: { ...DEFAULT_PREFS, ...(prefs ?? {}) } as EmailPrefs,
  };
}

export interface LogInput {
  recipientId: string | null;
  to: string;
  kind: string;
  locale: Loc;
  subject: string;
  status: DeliveryStatus;
  providerId?: string;
  error?: string;
  dedupeKey?: string | null;
}

/** Appends to `email_deliveries`. Never throws: a logging failure must not
 *  cost the caller its response (the mail has already been sent). */
export async function logDelivery(
  supa: SupabaseClient,
  input: LogInput,
): Promise<void> {
  const { error } = await supa.from("email_deliveries").insert({
    recipient_id: input.recipientId,
    to_email: input.to,
    kind: input.kind,
    locale: input.locale,
    subject: input.subject.slice(0, 300),
    status: input.status,
    provider_id: input.providerId ?? null,
    error: input.error ? input.error.slice(0, 500) : null,
    dedupe_key: input.dedupeKey ?? null,
  });
  if (error && error.code !== "23505") {
    // 23505 = the partial unique index on dedupe_key: a duplicate send was
    // correctly refused, which is the mechanism working, not a failure.
    console.error("email_deliveries insert failed", error.message);
  }
}

/** True when this exact mail was already sent (the dedupe key is claimed). */
export async function alreadySent(
  supa: SupabaseClient,
  dedupeKey: string,
): Promise<boolean> {
  const { data } = await supa
    .from("email_deliveries")
    .select("id")
    .eq("dedupe_key", dedupeKey)
    .eq("status", "sent")
    .limit(1)
    .maybeSingle();
  return Boolean(data);
}

export interface DeliverInput {
  recipient: Recipient;
  content: EmailContent;
  kind: string;
  /** Scope the unsubscribe link should switch off (null → no link). */
  scope: string | null;
  dedupeKey?: string | null;
}

/**
 * Send + log in one call. The caller has already decided the recipient wants
 * this mail; this handles the address check, the unsubscribe headers, the
 * provider call and the audit row.
 */
export async function deliver(
  supa: SupabaseClient,
  input: DeliverInput,
): Promise<SendResult> {
  const { recipient, content } = input;
  if (!recipient.email) {
    return { status: "skipped", error: "no address" };
  }
  if (input.dedupeKey && await alreadySent(supa, input.dedupeKey)) {
    return { status: "skipped", error: "already sent" };
  }

  const token = recipient.prefs.unsubscribe_token;
  // The header link carries the same scope as the one in the body, so a
  // client-level "unsubscribe" silences this category — not every email.
  const page = unsubscribeUrl(token, recipient.locale);
  const scopedPage = page && input.scope
    ? `${page}&scope=${encodeURIComponent(input.scope)}`
    : page;
  const result = await sendEmail({
    to: recipient.email,
    content,
    unsubscribeUrl: scopedPage,
    oneClickUrl: input.scope ? oneClickUrl(token, input.scope) : null,
    tag: input.kind,
  });

  await logDelivery(supa, {
    recipientId: recipient.id,
    to: recipient.email,
    kind: input.kind,
    locale: recipient.locale,
    subject: content.subject,
    status: result.status,
    providerId: result.id,
    error: result.error,
    // Only claim the key on a real send, so a provider outage can be retried.
    dedupeKey: result.status === "sent" ? input.dedupeKey ?? null : null,
  });

  return result;
}
