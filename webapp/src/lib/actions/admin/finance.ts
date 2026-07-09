"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { hasSupabase } from "@/lib/data/supabase-env";
import { createClient } from "@/lib/supabase/server";

/**
 * Finance actions. All three RPCs (0055) are `is_admin()`-gated SECURITY
 * DEFINER functions called with the user's own cookie client, mirroring
 * `actions/admin/moderation.ts`. In mock mode (no Supabase env) actions are
 * demo no-ops. On RPC failure the admin lands back on the page with
 * ?notice=err.
 */

function field(formData: FormData, name: string): string {
  const v = formData.get(name);
  return typeof v === "string" ? v.trim() : "";
}

function backPath(formData: FormData, page: string): string {
  const locale = field(formData, "locale") || "uz";
  return `/${locale}/admin/${page}`;
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

const TOPUP_STATUSES = new Set(["completed", "cancelled"]);

export async function setTopupStatus(formData: FormData): Promise<void> {
  const backTo = backPath(formData, "finance");
  const id = field(formData, "id");
  const status = field(formData, "status");
  if (!id || !TOPUP_STATUSES.has(status)) redirect(`${backTo}?notice=err`);
  await runAdminRpc(
    "admin_set_topup_status",
    { p_id: id, p_status: status },
    backTo,
  );
}

const ORDER_STATUSES = new Set(["paid", "cancelled", "refunded"]);

export async function setOrderStatus(formData: FormData): Promise<void> {
  const backTo = backPath(formData, "orders");
  const id = field(formData, "id");
  const status = field(formData, "status");
  if (!id || !ORDER_STATUSES.has(status)) redirect(`${backTo}?notice=err`);
  await runAdminRpc(
    "admin_set_order_status",
    { p_id: id, p_status: status },
    backTo,
  );
}

export async function setProductPrice(formData: FormData): Promise<void> {
  const backTo = backPath(formData, "orders");
  const code = field(formData, "code");
  const price = Number(field(formData, "priceUzs"));
  if (!code || !Number.isFinite(price) || price < 0) {
    redirect(`${backTo}?notice=err`);
  }
  await runAdminRpc(
    "admin_set_product_price",
    {
      p_code: code,
      p_price_uzs: price,
      p_is_active: field(formData, "isActive") !== "0",
    },
    backTo,
  );
}
