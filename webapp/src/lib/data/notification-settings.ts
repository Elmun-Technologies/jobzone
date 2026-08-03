import "server-only";

import { createClient as createSupabaseClient } from "@supabase/supabase-js";

import {
  DEFAULT_EMAIL_PREFS,
  type EmailPrefs,
  toEmailPrefs,
} from "@/lib/email-scopes";
import { createClient } from "@/lib/supabase/server";

import { hasSupabase } from "./supabase-env";

export interface NotificationPrefs extends EmailPrefs {
  push_messages: boolean;
  push_application: boolean;
  push_job_match: boolean;
  push_reviews: boolean;
}

export const DEFAULT_NOTIFICATION_PREFS: NotificationPrefs = {
  ...DEFAULT_EMAIL_PREFS,
  push_messages: true,
  push_application: true,
  push_job_match: true,
  push_reviews: true,
};

const COLUMNS =
  "push_messages, push_application, push_job_match, push_reviews, " +
  "email_messages, email_application, email_job_match, email_reviews, email_marketing";

/**
 * The signed-in user's notification preferences. The row is provisioned at
 * signup (handle_new_user), but a missing row must not blank the form — the
 * defaults below mirror the column defaults, so the switches show what the
 * backend would actually do.
 */
export async function getNotificationPrefs(): Promise<NotificationPrefs> {
  if (!hasSupabase()) return DEFAULT_NOTIFICATION_PREFS;
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return DEFAULT_NOTIFICATION_PREFS;

    const { data } = await supabase
      .from("notification_settings")
      .select(COLUMNS)
      .eq("profile_id", user.id)
      .maybeSingle();
    if (!data) return DEFAULT_NOTIFICATION_PREFS;

    // The generated select-string typing can't narrow a runtime column list,
    // so read the row structurally (each field is defaulted below anyway).
    const row = data as unknown as Record<string, unknown>;
    const bool = (key: keyof NotificationPrefs): boolean =>
      typeof row[key] === "boolean"
        ? (row[key] as boolean)
        : DEFAULT_NOTIFICATION_PREFS[key];
    return {
      ...toEmailPrefs(row),
      push_messages: bool("push_messages"),
      push_application: bool("push_application"),
      push_job_match: bool("push_job_match"),
      push_reviews: bool("push_reviews"),
    };
  } catch (e) {
    console.error("getNotificationPrefs failed", e);
    return DEFAULT_NOTIFICATION_PREFS;
  }
}

/**
 * Reads the preferences behind an unsubscribe token — the recipient of an
 * email is signed out by definition, so the token is the authorization. Uses a
 * cookie-free anon client; `email_prefs_by_token` is a SECURITY DEFINER RPC
 * that returns switches only, never the address or the profile id.
 */
export async function getEmailPrefsByToken(
  token: string,
): Promise<EmailPrefs | null> {
  if (!hasSupabase()) return null;
  try {
    const supabase = createSupabaseClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      { auth: { persistSession: false, autoRefreshToken: false } },
    );
    const { data, error } = await supabase.rpc("email_prefs_by_token", {
      p_token: token,
    });
    if (error || !data) return null;
    return toEmailPrefs(data);
  } catch (e) {
    console.error("getEmailPrefsByToken failed", e);
    return null;
  }
}
