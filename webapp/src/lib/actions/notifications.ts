"use server";

import { revalidatePath } from "next/cache";

import { createClient } from "@/lib/supabase/server";

/**
 * Marks one notification read. Fired on row click (fire-and-forget before
 * navigating to the notification's destination). RLS restricts the update to
 * the recipient's own rows.
 */
export async function markNotificationRead(
  id: string,
  locale: string,
): Promise<void> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return;
  await supabase
    .from("notifications")
    .update({ is_read: true })
    .eq("id", id)
    .eq("recipient_id", user.id);
  revalidatePath(`/${locale}/account/notifications`);
}

/** Marks every unread notification read (the list page's bulk action). */
export async function markAllNotificationsRead(locale: string): Promise<void> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return;
  await supabase
    .from("notifications")
    .update({ is_read: true })
    .eq("recipient_id", user.id)
    .eq("is_read", false);
  revalidatePath(`/${locale}/account/notifications`);
}
