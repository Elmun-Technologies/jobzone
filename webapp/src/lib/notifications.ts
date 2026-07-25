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
