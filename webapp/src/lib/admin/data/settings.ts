import "server-only";

import type { SiteBanner } from "@/lib/data/settings";
import { adminReadClient } from "./shared";

/** The banner setting for the admin form — unlike the public reader this
 *  returns the raw stored value even when disabled/empty so the form is
 *  pre-filled. `null` means the service-role read layer is unavailable. */
export async function getAdminSiteBanner(): Promise<SiteBanner | null> {
  const client = await adminReadClient();
  if (!client) return null;
  try {
    const { data } = await client
      .from("platform_settings")
      .select("value")
      .eq("key", "site_banner")
      .maybeSingle();
    const v = (data as { value?: Record<string, unknown> } | null)?.value ?? {};
    return {
      enabled: v.enabled === true,
      message: typeof v.message === "string" ? v.message : "",
      tone: v.tone === "warning" ? "warning" : "info",
    };
  } catch (e) {
    console.error("getAdminSiteBanner failed", e);
    return { enabled: false, message: "", tone: "info" };
  }
}
