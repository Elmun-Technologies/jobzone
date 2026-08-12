"use server";

import { revalidatePath } from "next/cache";
import { createClient as createSupabaseClient } from "@supabase/supabase-js";

import { hasSupabase } from "@/lib/data/supabase-env";
import {
  type EmailPrefs,
  isUnsubscribeToken,
  parseScope,
  toEmailPrefs,
} from "@/lib/email-scopes";
import { createClient } from "@/lib/supabase/server";

export interface PrefsFormState {
  ok?: boolean;
  error?: "signed_out" | "unknown";
}

const SWITCHES = [
  "push_messages",
  "push_application",
  "push_job_match",
  "push_reviews",
  "email_messages",
  "email_application",
  "email_job_match",
  "email_reviews",
  "email_marketing",
] as const;

/**
 * Saves the notification/email preferences form. Checkboxes only report when
 * checked, so every switch is read as "present = on" — which is why the form
 * submits the full set every time rather than a diff.
 *
 * RLS confines the row to its owner (`notification_settings own`), and the
 * upsert keys on profile_id so an account whose row somehow went missing is
 * repaired by the first save instead of silently doing nothing.
 */
export async function updateNotificationPrefs(
  _prev: PrefsFormState,
  formData: FormData,
): Promise<PrefsFormState> {
  const locale = (formData.get("locale") ?? "uz").toString();
  if (!hasSupabase()) return { error: "unknown" };

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: "signed_out" };

  const row: Record<string, unknown> = { profile_id: user.id };
  for (const key of SWITCHES) row[key] = formData.get(key) !== null;

  const { error } = await supabase
    .from("notification_settings")
    .upsert(row, { onConflict: "profile_id" });
  if (error) {
    console.error("updateNotificationPrefs failed", error.message);
    return { error: "unknown" };
  }

  revalidatePath(`/${locale}/account/settings`);
  return { ok: true };
}

export interface UnsubscribeState {
  prefs?: EmailPrefs;
  scope?: string;
  enabled?: boolean;
  error?: "invalid" | "unknown";
}

/**
 * Applies an unsubscribe (or its undo) from an emailed link. No session is
 * involved: the recipient is signed out by definition, so the token in the URL
 * is the authorization and `set_email_pref_by_token` (SECURITY DEFINER, 0084)
 * is the only thing it can do.
 */
export async function applyEmailPrefByToken(
  _prev: UnsubscribeState,
  formData: FormData,
): Promise<UnsubscribeState> {
  const token = (formData.get("token") ?? "").toString().trim();
  const scope = parseScope(formData.get("scope"));
  // The "resubscribe" button posts enabled=1; the unsubscribe button doesn't.
  const enabled = formData.get("enabled") !== null;

  if (!isUnsubscribeToken(token)) return { error: "invalid" };
  if (!hasSupabase()) return { error: "unknown" };

  try {
    const supabase = createSupabaseClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      { auth: { persistSession: false, autoRefreshToken: false } },
    );
    const { data, error } = await supabase.rpc("set_email_pref_by_token", {
      p_token: token,
      p_scope: scope,
      p_enabled: enabled,
    });
    if (error) {
      // A wrong/expired token is the common case and must read as "this link
      // is no longer valid", not as a platform error.
      return { error: error.code === "P0002" ? "invalid" : "unknown" };
    }
    return { prefs: toEmailPrefs(data), scope, enabled };
  } catch (e) {
    console.error("applyEmailPrefByToken failed", e);
    return { error: "unknown" };
  }
}
