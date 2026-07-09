import "server-only";

import { createClient as createSupabaseClient } from "@supabase/supabase-js";

import { hasSupabase } from "./supabase-env";

/** A site-wide announcement/maintenance banner (0057 `site_banner` setting). */
export interface SiteBanner {
  enabled: boolean;
  message: string;
  tone: "info" | "warning";
}

/**
 * Reads the announcement banner for the public site. Uses a cookie-free anon
 * client on purpose: platform_settings is world-readable, so this avoids the
 * `cookies()` call that would force every page (incl. the static SEO surfaces
 * that share the root layout) into dynamic rendering. Resilient — returns null
 * on offline / error / disabled so the layout simply renders nothing.
 */
export async function getSiteBanner(): Promise<SiteBanner | null> {
  if (!hasSupabase()) return null;
  try {
    const supabase = createSupabaseClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      { auth: { persistSession: false, autoRefreshToken: false } },
    );
    const { data } = await supabase
      .from("platform_settings")
      .select("value")
      .eq("key", "site_banner")
      .maybeSingle();
    const v = (data as { value?: Record<string, unknown> } | null)?.value;
    if (!v || v.enabled !== true) return null;
    const message = typeof v.message === "string" ? v.message.trim() : "";
    if (!message) return null;
    return {
      enabled: true,
      message,
      tone: v.tone === "warning" ? "warning" : "info",
    };
  } catch (e) {
    console.error("getSiteBanner failed", e);
    return null;
  }
}
