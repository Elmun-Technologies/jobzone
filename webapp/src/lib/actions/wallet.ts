"use server";

import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";

import {
  clickCheckoutUrl,
  paymeCheckoutUrl,
} from "@/lib/payments/checkout-url";
import { isValidTopUpAmount, parseTopUpAmount } from "@/lib/payments/topup";
import { createClient } from "@/lib/supabase/server";

export interface TopUpState {
  /** Recorded, but no gateway was available to charge it right away. */
  ok?: boolean;
  error?: "amount" | "signedOut" | "unknown";
}

function field(formData: FormData, name: string): string {
  return (formData.get(name) ?? "").toString().trim();
}

interface TopUpOrderRow {
  order_id: string;
  amount_uzs: number;
}

/**
 * Tops the employer's wallet up through the payment gateway.
 *
 * `create_topup_order` (0085) mints — or re-uses — the pending
 * `wallet_transactions` credit and bounds the amount server-side; the checkout
 * URL then addresses that row exactly as a vacancy order is addressed, and the
 * provider's callback flips it to `completed`, which is what moves the balance.
 * Re-using a same-amount pending row is deliberate: two payment attempts settle
 * the same row, so one intent can never be credited twice.
 *
 * With no merchant ids configured the row is still recorded and the form says
 * "awaiting confirmation" — the finance panel can complete it by hand, which is
 * how the platform ran before the gateways existed.
 */
export async function payTopUp(
  _prev: TopUpState,
  formData: FormData,
): Promise<TopUpState> {
  const locale = field(formData, "locale") || "uz";
  const companyId = field(formData, "companyId");
  const provider = field(formData, "provider");
  const amount = parseTopUpAmount(field(formData, "amount"));
  if (!companyId || !isValidTopUpAmount(amount)) return { error: "amount" };

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: "signedOut" };

  const { data, error } = await supabase.rpc("create_topup_order", {
    p_amount_uzs: amount,
    p_company_id: companyId,
  });
  const row = Array.isArray(data)
    ? (data[0] as TopUpOrderRow | undefined)
    : undefined;
  if (error || !row) {
    const msg = error?.message ?? "";
    return {
      error: msg.includes("amount_out_of_range") ? "amount" : "unknown",
    };
  }

  const h = await headers();
  const origin = `${h.get("x-forwarded-proto") ?? "https"}://${h.get("host") ?? ""}`;
  const returnUrl = `${origin}/${locale}/employer/wallet`;
  const amountUzs = Number(row.amount_uzs);

  let url: string | null = null;
  if (provider === "click") {
    const serviceId = process.env.NEXT_PUBLIC_CLICK_SERVICE_ID;
    const merchantId = process.env.NEXT_PUBLIC_CLICK_MERCHANT_ID;
    if (serviceId && merchantId) {
      url = clickCheckoutUrl({
        serviceId,
        merchantId,
        orderId: row.order_id,
        amountUzs,
        returnUrl,
      });
    }
  } else if (provider === "rahmat") {
    // Multicard's hosted checkout URL isn't static — `rahmat-invoice`
    // authenticates and asks for a fresh one for this order (re-checking
    // ownership and the amount server-side).
    if (process.env.NEXT_PUBLIC_RAHMAT_ENABLED === "1") {
      const { data: inv, error: invErr } = await supabase.functions.invoke<{
        ok: boolean;
        checkout_url?: string;
      }>("rahmat-invoice", {
        body: { order_id: row.order_id, return_url: returnUrl },
      });
      if (!invErr && inv?.ok && inv.checkout_url) url = inv.checkout_url;
    }
  } else if (provider === "payme") {
    const merchantId = process.env.NEXT_PUBLIC_PAYME_MERCHANT_ID;
    if (merchantId) {
      url = paymeCheckoutUrl({
        merchantId,
        orderId: row.order_id,
        amountUzs,
        returnUrl,
      });
    }
  }

  if (url) redirect(url);

  // No gateway for this choice: the pending credit stands, awaiting manual
  // confirmation. Refresh the wallet so the employer sees it in the ledger.
  revalidatePath(`/${locale}/employer/wallet`);
  return { ok: true };
}
