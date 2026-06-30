import "server-only";

import { createClient } from "@/lib/supabase/server";

import { hasSupabase } from "./supabase-env";

export interface WalletTransaction {
  id: string;
  kind: "topup" | "spend" | "refund" | "bonus";
  /** Signed amount in UZS: positive = credit, negative = debit. */
  amountUzs: number;
  status: "pending" | "completed" | "cancelled";
  description: string | null;
  createdAt: string | null;
}

export interface Wallet {
  balanceUzs: number;
  transactions: WalletTransaction[];
}

function toTransaction(row: Record<string, unknown>): WalletTransaction {
  const kind = String(row.kind ?? "topup");
  const status = String(row.status ?? "pending");
  return {
    id: String(row.id),
    kind: (["topup", "spend", "refund", "bonus"].includes(kind)
      ? kind
      : "topup") as WalletTransaction["kind"],
    amountUzs: Number(row.amount_uzs ?? 0),
    status: (["pending", "completed", "cancelled"].includes(status)
      ? status
      : "pending") as WalletTransaction["status"],
    description: typeof row.description === "string" ? row.description : null,
    createdAt: typeof row.created_at === "string" ? row.created_at : null,
  };
}

/**
 * The employer wallet for a company the user owns: the completed-entry balance
 * plus the recent transaction ledger. RLS confines both reads to the owner, so
 * a missing backend or any error degrades to an empty, zero-balance wallet.
 */
export async function getWallet(companyId: string): Promise<Wallet> {
  const empty: Wallet = { balanceUzs: 0, transactions: [] };
  if (!hasSupabase()) return empty;
  try {
    const supabase = await createClient();
    const [balanceRes, txRes] = await Promise.all([
      supabase
        .from("wallet_balances")
        .select("balance_uzs")
        .eq("company_id", companyId)
        .maybeSingle(),
      supabase
        .from("wallet_transactions")
        .select("id, kind, amount_uzs, status, description, created_at")
        .eq("company_id", companyId)
        .order("created_at", { ascending: false })
        .limit(50),
    ]);
    const balanceUzs = Number(
      (balanceRes.data as { balance_uzs?: unknown } | null)?.balance_uzs ?? 0,
    );
    const transactions = (txRes.data ?? []).map((row) =>
      toTransaction(row as Record<string, unknown>),
    );
    return { balanceUzs, transactions };
  } catch (e) {
    console.error("getWallet failed", e);
    return empty;
  }
}
