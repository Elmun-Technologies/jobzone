"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { hasSupabase } from "@/lib/data/supabase-env";
import { createClient } from "@/lib/supabase/server";

/**
 * Broadcast action. Calls the `is_admin()`-gated SECURITY DEFINER
 * `admin_broadcast` RPC (0056) with the user's own cookie client, so the DB
 * re-checks the actor, enforces the audience cap, and writes the audit row.
 * In mock mode (no Supabase env) it's a demo no-op. On success the admin lands
 * back with ?notice=sent&count=N; on failure with ?notice=err.
 */

function field(formData: FormData, name: string): string {
  const v = formData.get(name);
  return typeof v === "string" ? v.trim() : "";
}

const AUDIENCES = new Set(["all", "seekers", "employers"]);

export async function sendBroadcast(formData: FormData): Promise<void> {
  const locale = field(formData, "locale") || "uz";
  const backTo = `/${locale}/admin/broadcast`;
  const title = field(formData, "title");
  const body = field(formData, "body");
  const audience = field(formData, "audience");
  const city = field(formData, "city");
  if (!title || !AUDIENCES.has(audience)) redirect(`${backTo}?notice=err`);

  if (!hasSupabase()) {
    redirect(`${backTo}?notice=sent&count=0`);
  }
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("admin_broadcast", {
    p_title: title,
    p_body: body || null,
    p_audience: audience,
    p_city: city || null,
  });
  if (error) {
    console.error("admin_broadcast failed", error);
    redirect(`${backTo}?notice=err`);
  }
  revalidatePath(backTo);
  redirect(`${backTo}?notice=sent&count=${Number(data) || 0}`);
}
