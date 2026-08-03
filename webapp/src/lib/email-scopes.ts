/**
 * Email categories a recipient can switch off, shared by the unsubscribe page,
 * the one-click endpoint (RFC 8058) and the account preferences form. Every
 * value here must exist in `set_email_pref_by_token`'s allow-list (migration
 * 0084) — the DB is the real validator, this keeps a malformed link from
 * reaching it.
 */
export const EMAIL_SCOPES = [
  "all",
  "job_match",
  "marketing",
  "messages",
  "application",
  "reviews",
] as const;

export type EmailScope = (typeof EMAIL_SCOPES)[number];

/** The notification_settings column each scope maps to (all → every column). */
export const EMAIL_PREF_COLUMNS = {
  job_match: "email_job_match",
  marketing: "email_marketing",
  messages: "email_messages",
  application: "email_application",
  reviews: "email_reviews",
} as const;

export type EmailPrefColumn =
  (typeof EMAIL_PREF_COLUMNS)[keyof typeof EMAIL_PREF_COLUMNS];

/** A link's `scope` param → a known scope. Anything unknown means "all", which
 *  is the safest reading of "this person clicked unsubscribe". */
export function parseScope(value: unknown): EmailScope {
  const v = typeof value === "string" ? value.trim() : "";
  return (EMAIL_SCOPES as readonly string[]).includes(v)
    ? (v as EmailScope)
    : "all";
}

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Unsubscribe tokens are uuids; reject anything else before hitting the RPC. */
export function isUnsubscribeToken(value: unknown): value is string {
  return typeof value === "string" && UUID_RE.test(value.trim());
}

export interface EmailPrefs {
  email_job_match: boolean;
  email_marketing: boolean;
  email_messages: boolean;
  email_application: boolean;
  email_reviews: boolean;
}

export const DEFAULT_EMAIL_PREFS: EmailPrefs = {
  email_job_match: true,
  email_marketing: true,
  email_messages: false,
  email_application: true,
  email_reviews: false,
};

/** Normalizes whatever the RPC/table returned into a complete prefs object. */
export function toEmailPrefs(row: unknown): EmailPrefs {
  const r = (row ?? {}) as Record<string, unknown>;
  const bool = (key: keyof EmailPrefs): boolean =>
    typeof r[key] === "boolean"
      ? (r[key] as boolean)
      : DEFAULT_EMAIL_PREFS[key];
  return {
    email_job_match: bool("email_job_match"),
    email_marketing: bool("email_marketing"),
    email_messages: bool("email_messages"),
    email_application: bool("email_application"),
    email_reviews: bool("email_reviews"),
  };
}
