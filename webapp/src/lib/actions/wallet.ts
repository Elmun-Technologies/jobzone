"use server";

import { revalidatePath } from "next/cache";

import { createClient } from "@/lib/supabase/server";

export interface TopUpState {
  ok?: boolean;
  error?: "amount" | "signedOut" | "unknown";
}

function field(formData: FormData, name: string): string {
  return (formData.get(name) ?? "").toString().trim();
}

/**
 * Records a pending top-up request for the employer's wallet. Payments are
 * record-only for now: this inserts a `pending` credit (RLS confines it to the
 * owner) that a payment webhook later marks `completed` to move the balance.
 */
export async function requestTopUp(
  _prev: TopUpState,
  formData: FormData,
): Promise<TopUpState> {
  const locale = field(formData, "locale") || "uz";
  const companyId = field(formData, "companyId");
  const amount = Number(field(formData, "amount").replace(/\s+/g, ""));
  if (!companyId || !Number.isFinite(amount) || amount < 1000) {
    return { error: "amount" };
  }

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: "signedOut" };

  const { error } = await supabase.from("wallet_transactions").insert({
    company_id: companyId,
    kind: "topup",
    amount_uzs: Math.round(amount),
    status: "pending",
    created_by: user.id,
  });
  if (error) return { error: "unknown" };

  revalidatePath(`/${locale}/employer/wallet`);
  return { ok: true };
}
