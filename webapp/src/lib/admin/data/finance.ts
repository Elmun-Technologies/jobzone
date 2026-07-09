import "server-only";

import {
  mockAdminOrders,
  mockAdminProducts,
  mockAdminWalletTx,
} from "../mock";
import type {
  AdminList,
  AdminOrderRow,
  AdminProductRow,
  AdminWalletTxRow,
} from "../types";
import { adminReadClient, pageRange, toPage } from "./shared";
import { sanitizeQuery } from "./users";

export async function getAdminWalletTx(
  q: string,
  page: number,
): Promise<AdminList<AdminWalletTxRow>> {
  const client = await adminReadClient();
  if (client === "mock") return mockAdminWalletTx(q);
  if (!client) return null;
  try {
    const { from, to } = pageRange(page);
    let query = client
      .from("wallet_transactions")
      .select(
        "id, kind, amount_uzs, status, description, created_at, completed_at, companies(name)",
      )
      .order("created_at", { ascending: false })
      .range(from, to);
    const needle = sanitizeQuery(q);
    if (needle) query = query.ilike("description", `%${needle}%`);
    const { data, error } = await query;
    if (error) throw error;
    return toPage(
      (data ?? []).map((row) => {
        const r = row as Record<string, unknown>;
        const company = r.companies as { name?: unknown } | null;
        return {
          id: String(r.id),
          companyName: String(company?.name ?? "—"),
          kind: String(r.kind ?? ""),
          amountUzs: Number(r.amount_uzs ?? 0),
          status: String(r.status ?? "pending"),
          description: r.description ? String(r.description) : null,
          createdAt: String(r.created_at ?? ""),
          completedAt: r.completed_at ? String(r.completed_at) : null,
        };
      }),
    );
  } catch (e) {
    console.error("getAdminWalletTx failed", e);
    return { rows: [], hasNext: false };
  }
}

export async function getAdminOrders(
  q: string,
  page: number,
): Promise<AdminList<AdminOrderRow>> {
  const client = await adminReadClient();
  if (client === "mock") return mockAdminOrders(q);
  if (!client) return null;
  try {
    const { from, to } = pageRange(page);
    let query = client
      .from("promotion_orders")
      .select(
        "id, product_code, amount_uzs, status, created_at, paid_at, companies(name)",
      )
      .order("created_at", { ascending: false })
      .range(from, to);
    const needle = sanitizeQuery(q);
    if (needle) query = query.ilike("product_code", `%${needle}%`);
    const { data, error } = await query;
    if (error) throw error;
    return toPage(
      (data ?? []).map((row) => {
        const r = row as Record<string, unknown>;
        const company = r.companies as { name?: unknown } | null;
        return {
          id: String(r.id),
          companyName: String(company?.name ?? "—"),
          productCode: String(r.product_code ?? ""),
          amountUzs: Number(r.amount_uzs ?? 0),
          status: String(r.status ?? "pending"),
          createdAt: String(r.created_at ?? ""),
          paidAt: r.paid_at ? String(r.paid_at) : null,
        };
      }),
    );
  } catch (e) {
    console.error("getAdminOrders failed", e);
    return { rows: [], hasNext: false };
  }
}

/** The full promotion-product catalog (small, bounded) — no pagination. */
export async function getAdminProducts(): Promise<AdminProductRow[] | null> {
  const client = await adminReadClient();
  if (client === "mock") return mockAdminProducts();
  if (!client) return null;
  try {
    const { data, error } = await client
      .from("promotion_products")
      .select("code, name, kind, price_uzs, duration_days, is_active, sort_order")
      .order("sort_order", { ascending: true });
    if (error) throw error;
    return (data ?? []).map((row) => {
      const r = row as Record<string, unknown>;
      return {
        code: String(r.code),
        name: String(r.name ?? ""),
        kind: String(r.kind ?? ""),
        priceUzs: Number(r.price_uzs ?? 0),
        durationDays: r.duration_days == null ? null : Number(r.duration_days),
        isActive: Boolean(r.is_active ?? true),
        sortOrder: Number(r.sort_order ?? 0),
      };
    });
  } catch (e) {
    console.error("getAdminProducts failed", e);
    return [];
  }
}
