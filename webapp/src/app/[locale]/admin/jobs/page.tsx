import type { Metadata } from "next";

import { ActionNote } from "@/components/admin/action-note";
import { DataTable, type Column } from "@/components/admin/data-table";
import { ModerationForm } from "@/components/admin/moderation-form";
import { Pagination } from "@/components/admin/pagination";
import { ReadKeyMissing } from "@/components/admin/read-key-missing";
import { SearchInput } from "@/components/admin/search-input";
import { StatusBadge } from "@/components/admin/status-badge";
import { getAdminJobs } from "@/lib/admin/data/jobs";
import { adminStrings } from "@/lib/admin/strings";
import { pickParam } from "@/lib/admin/search-params";
import type { AdminJobRow } from "@/lib/admin/types";
import { setJobBlocked } from "@/lib/actions/admin/moderation";
import { requireAdmin } from "@/lib/auth/require-admin";
import { formatDate, groupNumber } from "@/lib/format";

export const metadata: Metadata = { title: adminStrings.nav.jobs };

// Session-gated admin page — render per request (the getCurrentUser() try/catch
// swallows the cookies() dynamic signal; without this Next would prerender one
// shared copy).
export const dynamic = "force-dynamic";

const s = adminStrings.mod;

const STATUS_TONE: Record<string, "ok" | "muted" | "warn"> = {
  open: "ok",
  draft: "muted",
  closed: "warn",
};
const STATUS_LABEL: Record<string, string> = {
  open: "Ochiq",
  draft: "Qoralama",
  closed: "Yopiq",
};

export default async function AdminJobsPage({
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

  const list = await getAdminJobs(q, page);
  if (!list) return <ReadKeyMissing />;

  const columns: Column<AdminJobRow>[] = [
    {
      key: "job",
      header: adminStrings.nav.jobs,
      render: (j) => (
        <div className="min-w-0">
          <p className="text-foreground font-medium">{j.title}</p>
          <p className="text-muted-foreground text-xs">{j.companyName}</p>
        </div>
      ),
    },
    { key: "city", header: "Shahar", render: (j) => j.city ?? "—" },
    {
      key: "state",
      header: "Holat",
      render: (j) => (
        <div className="flex flex-wrap gap-1.5">
          <StatusBadge tone={STATUS_TONE[j.status] ?? "muted"}>
            {STATUS_LABEL[j.status] ?? j.status}
          </StatusBadge>
          {j.blockedAt ? (
            <StatusBadge tone="destructive">{s.blocked}</StatusBadge>
          ) : null}
        </div>
      ),
    },
    {
      key: "applicants",
      header: "Arizalar",
      className: "text-right",
      render: (j) => (
        <span className="font-mono text-xs tabular-nums">
          {groupNumber(j.applicantsCount)}
        </span>
      ),
    },
    {
      key: "created",
      header: "Sana",
      className: "whitespace-nowrap",
      render: (j) => formatDate(j.createdAt),
    },
    {
      key: "actions",
      header: "Amallar",
      render: (j) => (
        <ModerationForm
          action={setJobBlocked}
          fields={{ locale, id: j.id, blocked: j.blockedAt ? "0" : "1" }}
          label={j.blockedAt ? s.unblock : s.block}
          withReason={!j.blockedAt}
        />
      ),
    },
  ];

  return (
    <div>
      <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-foreground text-2xl font-bold">
          {adminStrings.nav.jobs}
        </h1>
        <SearchInput defaultValue={q} />
      </div>
      {pickParam(sp.notice) === "err" ? (
        <ActionNote error={adminStrings.actionFailed} />
      ) : null}
      <DataTable columns={columns} rows={list.rows} rowKey={(j) => j.id} />
      <Pagination
        pathname="/admin/jobs"
        page={page}
        hasNext={list.hasNext}
        query={q ? { q } : {}}
      />
    </div>
  );
}
