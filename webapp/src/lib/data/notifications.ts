import "server-only";

import { createClient } from "@/lib/supabase/server";

import { hasSupabase } from "./supabase-env";

export type NotificationKind =
  | "job_match"
  | "message"
  | "application_update"
  | "review"
  | "system";

export interface WebNotification {
  id: string;
  kind: NotificationKind;
  title: string;
  body: string | null;
  isRead: boolean;
  createdAt: string | null;
  /** Type-specific payload, e.g. { job_id } for job_match. */
  data: Record<string, unknown>;
}

const KINDS: readonly NotificationKind[] = [
  "job_match",
  "message",
  "application_update",
  "review",
  "system",
];

function toKind(v: unknown): NotificationKind {
  return KINDS.includes(v as NotificationKind)
    ? (v as NotificationKind)
    : "system";
}

/**
 * The signed-in user's notifications, newest first. RLS confines the read to
 * the recipient; a missing backend or any error degrades to an empty list.
 */
export async function getNotifications(limit = 50): Promise<WebNotification[]> {
  if (!hasSupabase()) return [];
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return [];
    const { data, error } = await supabase
      .from("notifications")
      .select("id, type, title, body, is_read, created_at, data")
      .order("created_at", { ascending: false })
      .limit(limit);
    if (error) throw error;
    return (data ?? []).map((r) => {
      const row = r as Record<string, unknown>;
      return {
        id: String(row.id),
        kind: toKind(row.type),
        title: String(row.title ?? ""),
        body: typeof row.body === "string" && row.body ? row.body : null,
        isRead: Boolean(row.is_read),
        createdAt: typeof row.created_at === "string" ? row.created_at : null,
        data:
          row.data && typeof row.data === "object"
            ? (row.data as Record<string, unknown>)
            : {},
      };
    });
  } catch (e) {
    console.error("getNotifications failed", e);
    return [];
  }
}

/** Unread-notification count for the header bell. 0 for guests / offline. */
export async function getUnreadNotificationCount(): Promise<number> {
  if (!hasSupabase()) return 0;
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return 0;
    const { count, error } = await supabase
      .from("notifications")
      .select("id", { count: "exact", head: true })
      .eq("is_read", false);
    if (error) throw error;
    return count ?? 0;
  } catch (e) {
    console.error("getUnreadNotificationCount failed", e);
    return 0;
  }
}
