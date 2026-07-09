"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { hasSupabase } from "@/lib/data/supabase-env";
import { createClient } from "@/lib/supabase/server";

/**
 * Category CMS actions. Both RPCs (0053) are `is_admin()`-gated SECURITY
 * DEFINER functions called with the user's own cookie client, mirroring
 * `actions/admin/moderation.ts`. In mock mode (no Supabase env) actions are
 * demo no-ops. On RPC failure the admin lands back on the page with
 * ?notice=err.
 */

function field(formData: FormData, name: string): string {
  const v = formData.get(name);
  return typeof v === "string" ? v.trim() : "";
}

function backPath(formData: FormData): string {
  const locale = field(formData, "locale") || "uz";
  return `/${locale}/admin/categories`;
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

export async function upsertCategory(formData: FormData): Promise<void> {
  const backTo = backPath(formData);
  const id = field(formData, "id");
  const name = field(formData, "name");
  const slug = field(formData, "slug");
  if (!name || !slug) redirect(`${backTo}?notice=err`);

  await runAdminRpc(
    "admin_upsert_category",
    {
      p_id: id || null,
      p_name: name,
      p_slug: slug,
      p_icon: field(formData, "icon") || null,
      p_sort_order: Number(field(formData, "sortOrder")) || 0,
      p_is_active: field(formData, "isActive") !== "0",
    },
    backTo,
  );
}

export async function setCategoryActive(formData: FormData): Promise<void> {
  const backTo = backPath(formData);
  const id = field(formData, "id");
  if (!id) redirect(`${backTo}?notice=err`);

  await runAdminRpc(
    "admin_set_category_active",
    { p_id: id, p_active: field(formData, "active") === "1" },
    backTo,
  );
}
