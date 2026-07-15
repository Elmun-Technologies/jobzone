import "server-only";

import type { AdminTelegramChannelRow } from "../types";
import { adminReadClient } from "./shared";

/**
 * Every category+region -> Telegram channel mapping (0058) — the set is
 * small and bounded (one channel per category/region pair, capped by 12
 * categories x 14 regions), so like categories this returns everything in
 * one round trip, no pagination.
 */
export async function getAdminTelegramChannels(): Promise<
  AdminTelegramChannelRow[] | null
> {
  const client = await adminReadClient();
  if (!client) return null;
  try {
    const { data, error } = await client
      .from("telegram_channels")
      .select(
        "id, category_id, region, chat_id, title, is_active, created_at, job_categories(name)",
      )
      .order("created_at", { ascending: false });
    if (error) throw error;
    return (data ?? []).map((row) => {
      const r = row as Record<string, unknown>;
      const category = r.job_categories as { name?: string } | null;
      return {
        id: String(r.id),
        categoryId: String(r.category_id),
        categoryName: category?.name ? String(category.name) : "",
        region: r.region ? String(r.region) : null,
        chatId: String(r.chat_id),
        title: r.title ? String(r.title) : null,
        isActive: Boolean(r.is_active ?? true),
        createdAt: String(r.created_at ?? ""),
      };
    });
  } catch (e) {
    console.error("getAdminTelegramChannels failed", e);
    return [];
  }
}
