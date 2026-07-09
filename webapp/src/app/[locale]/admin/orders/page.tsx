import type { Metadata } from "next";

import { ActionNote } from "@/components/admin/action-note";
import { DataTable, type Column } from "@/components/admin/data-table";
import { ModerationForm } from "@/components/admin/moderation-form";
import { Pagination } from "@/components/admin/pagination";
import { SearchInput } from "@/components/admin/search-input";
import { StatusBadge } from "@/components/admin/status-badge";
import { EmptyState } from "@/components/ui/states";
import { getAdminOrders, getAdminProducts } from "@/lib/admin/data/finance";
import { adminStrings } from "@/lib/admin/strings";
import type { AdminOrderRow } from "@/lib/admin/types";
import { setOrderStatus, setProductPrice } from "@/lib/actions/admin/finance";
import { requireAdmin } from "@/lib/auth/require-admin";
import { formatDate, groupNumber } from "@/lib/format";

export const metadata: Metadata = { title: adminStrings.nav.orders };

// Session-gated admin page — render per request (the getCurrentUser() try/catch
// swallows the cookies() dynamic signal; without this Next would prerender one
// shared copy).
export const dynamic = "force-dynamic";

const s = adminStrings.finance;

const STATUS_TONE = {
  pending: "muted",
  paid: "ok",
  cancelled: "destructive",
  refunded: "destructive",
} as const;

const inputClass =
  "border-border bg-background text-foreground placeholder:text-muted-foreground h-9 rounded-lg border px-2.5 text-xs focus-visible:outline-none";

export default async function AdminOrdersPage({
  params,
  searchParams,
}: {
  params: Promise<{ locale: string }>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const { locale } = await params;
  await requireAdmin(locale);
  const sp = await searchParams;
  const pick = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
  const q = pick(sp.q) ?? "";
  const page = Math.max(1, Number(pick(sp.page)) || 1);

  const [list, products] = await Promise.all([
    getAdminOrders(q, page),
    getAdminProducts(),
  ]);
  if (!list || !products) {
    return (
      <EmptyState
        title={adminStrings.readKeyMissing}
        description={adminStrings.readKeyMissingHint}
      />
    );
  }

  const columns: Column<AdminOrderRow>[] = [
    {
      key: "company",
      header: s.company,
      render: (o) => <span className="text-foreground font-medium">{o.companyName}</span>,
    },
    { key: "product", header: s.product, render: (o) => o.productCode },
    {
      key: "amount",
      header: s.amount,
      className: "whitespace-nowrap font-mono tabular-nums",
      render: (o) => groupNumber(o.amountUzs),
    },
    {
      key: "status",
      header: s.status,
      render: (o) => (
        <StatusBadge tone={STATUS_TONE[o.status as keyof typeof STATUS_TONE] ?? "muted"}>
          {s[o.status as keyof typeof s] ?? o.status}
        </StatusBadge>
      ),
    },
    {
      key: "created",
      header: s.created,
      className: "whitespace-nowrap",
      render: (o) => formatDate(o.createdAt),
    },
    {
      key: "actions",
      header: "Amallar",
      render: (o) =>
        o.status === "pending" ? (
          <div className="flex flex-col gap-2">
            <ModerationForm
              action={setOrderStatus}
              fields={{ locale, id: o.id, status: "paid" }}
              label={s.markPaid}
            />
            <ModerationForm
              action={setOrderStatus}
              fields={{ locale, id: o.id, status: "cancelled" }}
              label={s.reject}
            />
          </div>
        ) : o.status === "paid" ? (
          <ModerationForm
            action={setOrderStatus}
            fields={{ locale, id: o.id, status: "refunded" }}
            label={s.refund}
          />
        ) : (
          "—"
        ),
    },
  ];

  return (
    <div>
      <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-foreground text-2xl font-bold">{adminStrings.nav.orders}</h1>
        <SearchInput defaultValue={q} />
      </div>
      {pick(sp.notice) === "err" ? <ActionNote error={adminStrings.actionFailed} /> : null}
      <DataTable columns={columns} rows={list.rows} rowKey={(o) => o.id} />
      <Pagination
        pathname="/admin/orders"
        page={page}
        hasNext={list.hasNext}
        query={q ? { q } : {}}
      />

      {/* Promotion product pricing */}
      <div className="mt-10">
        <h2 className="text-foreground mb-3 text-lg font-bold">{s.products}</h2>
        <div className="border-border overflow-x-auto rounded-xl border">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-border bg-muted/50 border-b text-left">
                <th className="text-muted-foreground px-4 py-3 text-xs font-semibold tracking-wide uppercase">
                  {s.product}
                </th>
                <th className="text-muted-foreground px-4 py-3 text-xs font-semibold tracking-wide uppercase">
                  {s.duration}
                </th>
                <th className="text-muted-foreground px-4 py-3 text-xs font-semibold tracking-wide uppercase">
                  {s.price}
                </th>
                <th className="text-muted-foreground px-4 py-3 text-xs font-semibold tracking-wide uppercase">
                  Amallar
                </th>
              </tr>
            </thead>
            <tbody>
              {products.map((p) => (
                <tr key={p.code} className="border-border border-b last:border-b-0">
                  <td className="px-4 py-3">
                    <p className="text-foreground font-medium">{p.name}</p>
                    <p className="text-muted-foreground font-mono text-xs">{p.code}</p>
                  </td>
                  <td className="px-4 py-3">{p.durationDays ?? "—"}</td>
                  <td className="px-4 py-3" colSpan={2}>
                    <form
                      action={setProductPrice}
                      className="flex flex-wrap items-center gap-2"
                    >
                      <input type="hidden" name="locale" value={locale} />
                      <input type="hidden" name="code" value={p.code} />
                      <input type="hidden" name="isActive" value={p.isActive ? "1" : "0"} />
                      <input
                        name="priceUzs"
                        type="number"
                        min={0}
                        defaultValue={p.priceUzs}
                        className={`${inputClass} w-32`}
                      />
                      <button
                        type="submit"
                        className="border-border bg-background text-foreground hover:bg-muted h-9 rounded-full border px-3 text-xs font-semibold"
                      >
                        {adminStrings.save}
                      </button>
                    </form>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
