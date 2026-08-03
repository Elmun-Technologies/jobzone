/**
 * Notification shape + routing, shared by the server reader
 * (`lib/data/notifications.ts`), the account list and the realtime toast
 * listener. Deliberately free of `server-only` so client components can import
 * it — the listener needs the same deep-link rules the list page uses, and two
 * copies would drift.
 */

export type NotificationKind =
  "job_match" | "message" | "application_update" | "review" | "system";

const KINDS: readonly NotificationKind[] = [
  "job_match",
  "message",
  "application_update",
  "review",
  "system",
];

/** Narrow an unknown `type` column to a known kind; anything else is system. */
export function toNotificationKind(v: unknown): NotificationKind {
  return KINDS.includes(v as NotificationKind)
    ? (v as NotificationKind)
    : "system";
}

/**
 * Where a notification leads, as a locale-relative path — `job_match`
 * deep-links to the vacancy, completing the saved-search alert loop on the web.
 * Returns null for informational rows that have nowhere to go.
 */
/**
 * Message key under `notifications.` for a localized title, or null when the
 * stored title is real content that has to be shown exactly as written.
 *
 * The triggers that raise these rows store a fixed-language title — 0005 writes
 * the literal English "Application update" and "New message" — so rendering the
 * column verbatim showed an Uzbek-speaking seeker English at the one moment
 * that matters most to them. The mobile app has re-derived both from the type
 * since it shipped (`notification_display.dart`); this is the same rule.
 *
 * `job_match` is left alone on purpose: its title is the vacancy's own name
 * (0036), which is content, not copy. `review`/`system` carry admin-authored
 * broadcast text that is already written in the language it should appear in.
 */
export function notificationTitleKey(
  kind: NotificationKind,
  data: Record<string, unknown> = {},
): string | null {
  switch (kind) {
    case "application_update":
      // A vacancy closing is not a decision on the application, so it gets its
      // own heading rather than the generic "your application changed".
      return isJobClosed(data) ? "typeJobClosed" : "typeApplicationUpdate";
    case "message":
      return "typeMessage";
    default:
      return null;
  }
}

/**
 * Whether this row is the "the vacancy you applied to was closed" notice
 * raised by 0078, rather than an ordinary status change.
 *
 * The trigger writes the vacancy's title as the body and marks the row with
 * `event`, precisely so the sentence around that title can be written in the
 * reader's language here instead of being fixed in SQL.
 */
export function isJobClosed(data: Record<string, unknown>): boolean {
  return data.event === "job_closed";
}

/** Statuses `applications.status.*` has a label for (mirrors the DB enum). */
const APPLICATION_STATUSES: readonly string[] = [
  "submitted",
  "viewed",
  "shortlisted",
  "interview",
  "offer",
  "rejected",
  "hired",
  "withdrawn",
];

/**
 * The status an `application_update` row carries, when it is one the UI can
 * label. Null means "keep the stored body" — for a chat message that is the
 * message preview, and for an unrecognised status the server sentence is still
 * better than nothing.
 *
 * notify_application_status() (0005) always writes `data.status`, so the null
 * branch is the guard against a future status the web build predates.
 */
export function notificationStatus(
  kind: NotificationKind,
  data: Record<string, unknown>,
): string | null {
  // A close notice carries no status — its body is the vacancy's title.
  if (kind !== "application_update" || isJobClosed(data)) return null;
  const status = data.status;
  return typeof status === "string" && APPLICATION_STATUSES.includes(status)
    ? status
    : null;
}

export function notificationHref(
  kind: NotificationKind,
  data: Record<string, unknown>,
): string | null {
  const str = (k: string): string | null => {
    const v = data[k];
    return typeof v === "string" && v ? v : null;
  };
  switch (kind) {
    case "job_match": {
      const id = str("job_id");
      return id ? `/jobs/${id}` : null;
    }
    case "message": {
      const id = str("conversation_id");
      return id ? `/account/messages/${id}` : "/account/messages";
    }
    case "application_update":
      return "/account/applications";
    default:
      return null;
  }
}
