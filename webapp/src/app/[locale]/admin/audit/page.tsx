import type { Metadata } from "next";

import { DataTable, type Column } from "@/components/admin/data-table";
import { Pagination } from "@/components/admin/pagination";
import { ReadKeyMissing } from "@/components/admin/read-key-missing";
import { getAdminAudit } from "@/lib/admin/data/audit";
import { adminStrings } from "@/lib/admin/strings";
import { pickParam } from "@/lib/admin/search-params";
import type { AdminAuditRow } from "@/lib/admin/types";
import { requireAdmin } from "@/lib/auth/require-admin";
import { formatDate, tashkentClock } from "@/lib/format";

export const metadata: Metadata = { title: adminStrings.nav.audit };

// Session-gated admin page — render per request (the getCurrentUser() try/catch
// swallows the cookies() dynamic signal; without this Next would prerender one
// shared copy).
export const dynamic = "force-dynamic";

export default async function AdminAuditPage({
  params,
  searchParams,
}: {
  params: Promise<{ locale: string }>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const { locale } = await params;
  await requireAdmin(locale);
  const sp = await searchParams;
  const page = Math.max(1, Number(pickParam(sp.page)) || 1);

  const list = await getAdminAudit(page);
  if (!list) return <ReadKeyMissing />;

  const columns: Column<AdminAuditRow>[] = [
    {
      key: "when",
      header: "Vaqt",
      className: "whitespace-nowrap",
      render: (a) => (
        <span className="font-mono text-xs tabular-nums">
          {formatDate(a.createdAt)} {tashkentClock(a.createdAt)}
        </span>
      ),
    },
    { key: "actor", header: "Admin", render: (a) => a.actorName },
    {
      key: "action",
      header: "Amal",
      render: (a) => <span className="font-mono text-xs">{a.action}</span>,
    },
    {
      key: "target",
      header: "Obyekt",
      render: (a) => (
        <span className="text-muted-foreground font-mono text-xs">
          {a.targetType ? `${a.targetType}/${a.targetId ?? ""}` : "—"}
        </span>
      ),
    },
    {
      key: "reason",
      header: "Izoh",
      className: "max-w-sm",
      render: (a) => (
        <p className="text-muted-foreground line-clamp-2 text-xs">
          {typeof a.meta.reason === "string" && a.meta.reason ? a.meta.reason : "—"}
        </p>
      ),
    },
  ];

  return (
    <div>
      <h1 className="text-foreground mb-5 text-2xl font-bold">
        {adminStrings.nav.audit}
      </h1>
      <DataTable columns={columns} rows={list.rows} rowKey={(a) => String(a.id)} />
      <Pagination pathname="/admin/audit" page={page} hasNext={list.hasNext} />
    </div>
  );
}
