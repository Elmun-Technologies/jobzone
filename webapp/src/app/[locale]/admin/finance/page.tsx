import type { Metadata } from "next";

import { ActionNote } from "@/components/admin/action-note";
import { DataTable, type Column } from "@/components/admin/data-table";
import { ManualCreditForm } from "@/components/admin/manual-credit-form";
import { ModerationForm } from "@/components/admin/moderation-form";
import { Pagination } from "@/components/admin/pagination";
import { ReadKeyMissing } from "@/components/admin/read-key-missing";
import { SearchInput } from "@/components/admin/search-input";
import { StatusBadge } from "@/components/admin/status-badge";
import { getAdminWalletTx } from "@/lib/admin/data/finance";
import { adminStrings } from "@/lib/admin/strings";
import { pickParam } from "@/lib/admin/search-params";
import type { AdminWalletTxRow } from "@/lib/admin/types";
import { setTopupStatus } from "@/lib/actions/admin/finance";
import { requireAdmin } from "@/lib/auth/require-admin";
import { formatDate, groupNumber } from "@/lib/format";

export const metadata: Metadata = { title: adminStrings.nav.wallet };

// Session-gated admin page — render per request (the getCurrentUser() try/catch
// swallows the cookies() dynamic signal; without this Next would prerender one
// shared copy).
export const dynamic = "force-dynamic";

const s = adminStrings.finance;

const KIND_LABEL: Record<string, string> = {
  topup: s.kindTopup,
  spend: s.kindSpend,
  refund: s.kindRefund,
  bonus: s.kindBonus,
};

const STATUS_TONE = {
  pending: "muted",
  completed: "ok",
  cancelled: "destructive",
} as const;

export default async function AdminFinancePage({
  params,
  searchParams,
}: {
  params: Promise<{ locale: string }>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const { locale } = await params;
  await requireAdmin(locale);
  const sp = await searchParams;
  const q = pickParam(sp.q) ?? "";
  const page = Math.max(1, Number(pickParam(sp.page)) || 1);

  const list = await getAdminWalletTx(q, page);
  if (!list) return <ReadKeyMissing />;

  const columns: Column<AdminWalletTxRow>[] = [
    {
      key: "company",
      header: s.company,
      render: (t) => <span className="text-foreground font-medium">{t.companyName}</span>,
    },
    { key: "kind", header: s.kind, render: (t) => KIND_LABEL[t.kind] ?? t.kind },
    {
      key: "amount",
      header: s.amount,
      className: "whitespace-nowrap font-mono tabular-nums",
      render: (t) => `${t.amountUzs > 0 ? "+" : ""}${groupNumber(t.amountUzs)}`,
    },
    { key: "description", header: s.description, render: (t) => t.description ?? "—" },
    {
      key: "status",
      header: s.status,
      render: (t) => (
        <StatusBadge tone={STATUS_TONE[t.status as keyof typeof STATUS_TONE] ?? "muted"}>
          {s[t.status as keyof typeof s] ?? t.status}
        </StatusBadge>
      ),
    },
    {
      key: "created",
      header: s.created,
      className: "whitespace-nowrap",
      render: (t) => formatDate(t.createdAt),
    },
    {
      key: "actions",
      header: "Amallar",
      render: (t) =>
        t.kind === "topup" && t.status === "pending" ? (
          <div className="flex flex-col gap-2">
            <ModerationForm
              action={setTopupStatus}
              fields={{ locale, id: t.id, status: "completed" }}
              label={s.approve}
            />
            <ModerationForm
              action={setTopupStatus}
              fields={{ locale, id: t.id, status: "cancelled" }}
              label={s.reject}
            />
          </div>
        ) : (
          "—"
        ),
    },
  ];

  return (
    <div>
      <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-foreground text-2xl font-bold">{adminStrings.nav.wallet}</h1>
        <SearchInput defaultValue={q} />
      </div>
      {pickParam(sp.notice) === "err" ? <ActionNote error={adminStrings.actionFailed} /> : null}
      <ManualCreditForm locale={locale} />
      <DataTable columns={columns} rows={list.rows} rowKey={(t) => t.id} />
      <Pagination
        pathname="/admin/finance"
        page={page}
        hasNext={list.hasNext}
        query={q ? { q } : {}}
      />
    </div>
  );
}
