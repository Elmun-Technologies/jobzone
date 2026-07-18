import type { Metadata } from "next";

import { DataTable, type Column } from "@/components/admin/data-table";
import { Pagination } from "@/components/admin/pagination";
import { ReadKeyMissing } from "@/components/admin/read-key-missing";
import { ReportActions } from "@/components/admin/report-actions";
import { StatusBadge } from "@/components/admin/status-badge";
import { buttonVariants } from "@/components/ui/button";
import { pickParam } from "@/lib/admin/search-params";
import { getAdminReports, type AdminReportRow } from "@/lib/admin/data/reports";
import { adminStrings } from "@/lib/admin/strings";
import { requireAdmin } from "@/lib/auth/require-admin";
import { formatDate } from "@/lib/format";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

export const metadata: Metadata = { title: adminStrings.nav.reports };

// Session-gated admin page — render per request.
export const dynamic = "force-dynamic";

const TARGET_HREF: Record<AdminReportRow["targetType"], (id: string) => string> = {
  job: (id) => `/jobs/${id}`,
  company: (id) => `/companies/${id}`,
  // Reviews live inside company pages; jump to the company for now.
  review: (id) => `/companies/${id}`,
};

const STATUS_TONE: Record<string, "destructive" | "ok" | "muted"> = {
  open: "destructive",
  reviewed: "muted",
  dismissed: "muted",
  action_taken: "ok",
};

// Ru/uz labels for the enums — this admin panel is intentionally uz-only.
const TARGET_LABEL: Record<AdminReportRow["targetType"], string> = {
  job: "Vakansiya",
  company: "Kompaniya",
  review: "Sharh",
};
const REASON_LABEL: Record<string, string> = {
  spam: "Spam",
  scam: "Firibgarlik",
  misleading: "Chalg'ituvchi",
  discrimination: "Kamsitish",
  illegal: "Noqonuniy",
  inappropriate: "Nomaqbul",
  personal_info: "Shaxsiy ma'lumot",
  other: "Boshqa",
};
const STATUS_LABEL: Record<string, string> = {
  open: "Ochiq",
  reviewed: "Ko'rilgan",
  dismissed: "Rad etilgan",
  action_taken: "Chora ko'rilgan",
};

export default async function AdminReportsPage({
  params,
  searchParams,
}: {
  params: Promise<{ locale: string }>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const { locale } = await params;
  await requireAdmin(locale);
  const sp = await searchParams;
  const filter = pickParam(sp.filter) === "all" ? "all" : "open";
  const page = Math.max(1, Number(pickParam(sp.page)) || 1);

  const list = await getAdminReports(filter, page);
  if (!list) return <ReadKeyMissing />;

  const columns: Column<AdminReportRow>[] = [
    {
      key: "target",
      header: "Nishon",
      render: (r) => (
        <div>
          <div className="text-foreground font-medium">
            {TARGET_LABEL[r.targetType]}
          </div>
          <Link
            href={TARGET_HREF[r.targetType](r.targetId)}
            className="text-primary text-xs hover:underline"
          >
            {r.targetId.slice(0, 8)}…
          </Link>
        </div>
      ),
    },
    { key: "reason", header: "Sabab", render: (r) => REASON_LABEL[r.reason] ?? r.reason },
    {
      key: "details",
      header: "Tafsilotlar",
      className: "max-w-sm",
      render: (r) => (
        <p className="text-muted-foreground line-clamp-2 text-xs">
          {r.details ?? "—"}
        </p>
      ),
    },
    { key: "reporter", header: "Shikoyatchi", render: (r) => r.reporterName },
    {
      key: "created",
      header: "Sana",
      className: "whitespace-nowrap",
      render: (r) => formatDate(r.createdAt),
    },
    {
      key: "status",
      header: "Holat",
      render: (r) => (
        <StatusBadge tone={STATUS_TONE[r.status] ?? "muted"}>
          {STATUS_LABEL[r.status] ?? r.status}
        </StatusBadge>
      ),
    },
    {
      key: "actions",
      header: "Amallar",
      render: (r) => (r.status === "open" ? <ReportActions reportId={r.id} /> : null),
    },
  ];

  return (
    <div>
      <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-foreground text-2xl font-bold">
          {adminStrings.nav.reports}
        </h1>
        <div className="flex gap-2">
          {(
            [
              ["open", "Ochiq"],
              ["all", "Barchasi"],
            ] as const
          ).map(([key, label]) => (
            <Link
              key={key}
              href={{
                pathname: "/admin/reports",
                query: key === "open" ? {} : { filter: key },
              }}
              className={cn(
                buttonVariants({
                  variant: filter === key ? "primary" : "outline",
                  size: "sm",
                }),
              )}
            >
              {label}
            </Link>
          ))}
        </div>
      </div>
      <DataTable
        columns={columns}
        rows={list.rows}
        rowKey={(r) => String(r.id)}
      />
      <Pagination
        pathname="/admin/reports"
        page={page}
        hasNext={list.hasNext}
        query={filter === "open" ? {} : { filter }}
      />
    </div>
  );
}
