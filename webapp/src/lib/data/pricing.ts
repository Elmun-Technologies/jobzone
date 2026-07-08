import "server-only";

import { createClient } from "@/lib/supabase/server";

import { hasSupabase } from "./supabase-env";

/**
 * Price (UZS) to publish a vacancy beyond the employer's free first one.
 * Lives in `promotion_products` (catalog, not app code) like boost prices.
 * Degrades to free (0) on any error/offline/missing-row — a pricing-lookup
 * hiccup should never block a legitimate Publish; it can only under-charge.
 */
export async function getJobPostPrice(): Promise<number> {
  if (!hasSupabase()) return 0;
  try {
    const supabase = await createClient();
    const { data } = await supabase
      .from("promotion_products")
      .select("price_uzs")
      .eq("code", "job_post")
      .eq("is_active", true)
      .maybeSingle();
    const price = Number(
      (data as { price_uzs?: unknown } | null)?.price_uzs ?? 0,
    );
    return Number.isFinite(price) && price > 0 ? price : 0;
  } catch (e) {
    console.error("getJobPostPrice failed", e);
    return 0;
  }
}

/** A purchasable visibility boost (reklama) for a live vacancy. */
export interface PromotionProduct {
  code: string;
  name: string;
  description: string | null;
  kind: "top" | "featured";
  priceUzs: number;
  durationDays: number;
}

/** Catalog fallback (mirrors the 0011 seed) so the promote page still renders
 * a real-looking package list offline / on any read error. Buying is a no-op
 * without a backend, but the demo stays whole. */
const FALLBACK_PROMOTIONS: PromotionProduct[] = [
  {
    code: "featured",
    name: "Tezkor topish",
    description: "Kategoriyada ajratib ko'rsatish",
    kind: "featured",
    priceUzs: 10000,
    durationDays: 7,
  },
  {
    code: "top_3",
    name: "3 kun TOP",
    description: "Ro'yxat tepasida 3 kun",
    kind: "top",
    priceUzs: 15000,
    durationDays: 3,
  },
  {
    code: "top_7",
    name: "7 kun TOP",
    description: "Ro'yxat tepasida 7 kun",
    kind: "top",
    priceUzs: 35000,
    durationDays: 7,
  },
  {
    code: "top_30",
    name: "30 kun TOP",
    description: "Ro'yxat tepasida 30 kun",
    kind: "top",
    priceUzs: 99000,
    durationDays: 30,
  },
];

/**
 * The paid, time-boxed promotions an employer can buy for a vacancy (the `top`
 * and `featured` kinds — never the free base tier, the job_post posting fee, or
 * the not-yet-live AI tier). Ordered cheapest-first via sort_order. Degrades to
 * the seeded fallback catalog on any error/offline so the page never renders
 * empty.
 */
export async function getPromotionProducts(): Promise<PromotionProduct[]> {
  if (!hasSupabase()) return FALLBACK_PROMOTIONS;
  try {
    const supabase = await createClient();
    const { data } = await supabase
      .from("promotion_products")
      .select("code, name, description, kind, price_uzs, duration_days")
      .eq("is_active", true)
      .in("kind", ["top", "featured"])
      .gt("price_uzs", 0)
      .order("sort_order", { ascending: true });
    const rows = (data ?? []) as Record<string, unknown>[];
    const products = rows
      .filter((r) => Number(r.duration_days ?? 0) > 0)
      .map((r) => ({
        code: String(r.code),
        name: String(r.name ?? ""),
        description: typeof r.description === "string" ? r.description : null,
        kind: (r.kind === "top" ? "top" : "featured") as "top" | "featured",
        priceUzs: Number(r.price_uzs ?? 0),
        durationDays: Number(r.duration_days ?? 0),
      }));
    return products.length ? products : FALLBACK_PROMOTIONS;
  } catch (e) {
    console.error("getPromotionProducts failed", e);
    return FALLBACK_PROMOTIONS;
  }
}
