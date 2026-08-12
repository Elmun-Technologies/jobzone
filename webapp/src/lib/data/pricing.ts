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
