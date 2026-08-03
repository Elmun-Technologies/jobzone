import "server-only";

import { unstable_cache } from "next/cache";

import { createPublicClient } from "@/lib/supabase/server";

import { hasSupabase } from "./supabase-env";

/**
 * The Telegram channels a vacancy is auto-posted to (0058), read for the
 * public employer page.
 *
 * This is the platform's distribution and, until now, it was invisible: the
 * mapping existed only in the admin CMS, so an employer deciding where to post
 * had no way to know their vacancy also reaches a channel for their trade and
 * their region. Saying it — with the real list, not a claim — is the strongest
 * argument the employer side has.
 */

const REVALIDATE = 3600;

export interface PublicTelegramChannel {
  id: string;
  /** Channel name as the team entered it, or the handle as a fallback. */
  title: string;
  /** Public @handle, when the channel was mapped by username rather than id. */
  handle: string | null;
  /** t.me link, or null for a channel mapped by numeric chat id. */
  url: string | null;
  categoryName: string;
  /** Canonical viloyat, or null for the category's catch-all channel. */
  region: string | null;
}

const _getPublicTelegramChannels = unstable_cache(
  async (): Promise<PublicTelegramChannel[]> => {
    const supabase = createPublicClient();
    const { data, error } = await supabase
      .from("telegram_channels")
      .select("id, region, chat_id, title, job_categories(name)")
      .eq("is_active", true);
    if (error) throw error;
    return (data ?? [])
      .map((row) => {
        const r = row as Record<string, unknown>;
        const chatId = String(r.chat_id ?? "");
        // The CMS accepts either a numeric chat id or a public @username; only
        // the latter can be linked, and only it is safe to show.
        const handle = chatId.startsWith("@") ? chatId : null;
        const category = r.job_categories as { name?: string } | null;
        return {
          id: String(r.id),
          title: r.title ? String(r.title) : (handle ?? ""),
          handle,
          url: handle ? `https://t.me/${handle.slice(1)}` : null,
          categoryName: category?.name ? String(category.name) : "",
          region: r.region ? String(r.region) : null,
        };
      })
      .filter((c) => c.title !== "")
      .sort((a, b) => a.categoryName.localeCompare(b.categoryName));
  },
  ["public-telegram-channels"],
  { tags: ["telegram-channels"], revalidate: REVALIDATE },
);

/** Active channels for the public employer page (empty when unconfigured). */
export async function getPublicTelegramChannels(): Promise<
  PublicTelegramChannel[]
> {
  if (!hasSupabase()) return [];
  try {
    return await _getPublicTelegramChannels();
  } catch (e) {
    console.error("getPublicTelegramChannels failed", e);
    return [];
  }
}
