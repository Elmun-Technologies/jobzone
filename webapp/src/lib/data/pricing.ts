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

/**
 * The paid, time-boxed promotions an employer can buy for a vacancy (the `top`
 * and `featured` kinds — never the free base tier, the job_post posting fee, or
 * the not-yet-live AI tier). Ordered cheapest-first via sort_order. Returns an
 * empty list on any read error / when the backend is unreachable — the promote
 * page's own empty state handles the "no packages available" case gracefully.
 * We intentionally do NOT ship a hardcoded fallback catalog: launch invariant
 * is "no demo data", and stale prices would mislead the employer.
 */
export async function getPromotionProducts(): Promise<PromotionProduct[]> {
  if (!hasSupabase()) return [];
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
    return products;
  } catch (e) {
    console.error("getPromotionProducts failed", e);
    return [];
  }
}
