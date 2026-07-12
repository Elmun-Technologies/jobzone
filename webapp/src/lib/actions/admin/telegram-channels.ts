"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { hasSupabase } from "@/lib/data/supabase-env";
import { createClient } from "@/lib/supabase/server";

/**
 * Telegram channel CMS actions (0058). Both RPCs are `is_admin()`-gated
 * SECURITY DEFINER functions called with the user's own cookie client,
 * mirroring `actions/admin/categories.ts`.
 */

function field(formData: FormData, name: string): string {
  const v = formData.get(name);
  return typeof v === "string" ? v.trim() : "";
}

function backPath(formData: FormData): string {
  const locale = field(formData, "locale") || "uz";
  return `/${locale}/admin/telegram-channels`;
}

async function runAdminRpc(
  fn: string,
  args: Record<string, unknown>,
  backTo: string,
): Promise<void> {
  if (!hasSupabase()) {
    revalidatePath(backTo);
    return;
  }
  const supabase = await createClient();
  const { error } = await supabase.rpc(fn, args);
  if (error) {
    console.error(`${fn} failed`, error);
    redirect(`${backTo}?notice=err`);
  }
  revalidatePath(backTo);
}

export async function upsertTelegramChannel(formData: FormData): Promise<void> {
  const backTo = backPath(formData);
  const id = field(formData, "id");
  const categoryId = field(formData, "categoryId");
  const chatId = field(formData, "chatId");
  if (!categoryId || !chatId) redirect(`${backTo}?notice=err`);

  await runAdminRpc(
    "admin_upsert_telegram_channel",
    {
      p_id: id || null,
      p_category_id: categoryId,
      p_region: field(formData, "region") || null,
      p_chat_id: chatId,
      p_title: field(formData, "title") || null,
      p_is_active: field(formData, "isActive") !== "0",
    },
    backTo,
  );
}

export async function setTelegramChannelActive(formData: FormData): Promise<void> {
  const backTo = backPath(formData);
  const id = field(formData, "id");
  if (!id) redirect(`${backTo}?notice=err`);

  await runAdminRpc(
    "admin_set_telegram_channel_active",
    { p_id: id, p_active: field(formData, "active") === "1" },
    backTo,
  );
}
