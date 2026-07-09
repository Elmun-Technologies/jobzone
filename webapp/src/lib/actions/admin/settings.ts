"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { hasSupabase } from "@/lib/data/supabase-env";
import { createClient } from "@/lib/supabase/server";

/**
 * Settings actions. Calls the `is_admin()`-gated SECURITY DEFINER
 * `admin_set_setting` RPC (0057) with the user's own cookie client. In mock
 * mode (no Supabase env) it's a demo no-op. On failure the admin lands back
 * with ?notice=err, on success ?notice=saved.
 */

function field(formData: FormData, name: string): string {
  const v = formData.get(name);
  return typeof v === "string" ? v.trim() : "";
}

export async function setSiteBanner(formData: FormData): Promise<void> {
  const locale = field(formData, "locale") || "uz";
  const backTo = `/${locale}/admin/settings`;

  const value = {
    enabled: field(formData, "enabled") === "1",
    message: field(formData, "message"),
    tone: field(formData, "tone") === "warning" ? "warning" : "info",
  };

  if (!hasSupabase()) {
    redirect(`${backTo}?notice=saved`);
  }
  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_set_setting", {
    p_key: "site_banner",
    p_value: value,
  });
  if (error) {
    console.error("admin_set_setting failed", error);
    redirect(`${backTo}?notice=err`);
  }
  revalidatePath(backTo);
  // The banner shows site-wide; refresh the shared layout's cached reads.
  revalidatePath("/", "layout");
  redirect(`${backTo}?notice=saved`);
}
