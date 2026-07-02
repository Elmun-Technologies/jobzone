import type { Metadata } from "next";

import { ActionNote } from "@/components/admin/action-note";
import { DataTable, type Column } from "@/components/admin/data-table";
import { ModerationForm } from "@/components/admin/moderation-form";
import { Pagination } from "@/components/admin/pagination";
import { SearchInput } from "@/components/admin/search-input";
import { StatusBadge } from "@/components/admin/status-badge";
import { EmptyState } from "@/components/ui/states";
import { getAdminUsers } from "@/lib/admin/data/users";
import { adminStrings } from "@/lib/admin/strings";
import type { AdminUserRow } from "@/lib/admin/types";
import { setProfileSuspended, verifyWorker } from "@/lib/actions/admin/moderation";
import { requireAdmin } from "@/lib/auth/require-admin";
import { formatDate } from "@/lib/format";

export const metadata: Metadata = { title: adminStrings.nav.users };

// Session-gated admin page — render per request (the getCurrentUser() try/catch
// swallows the cookies() dynamic signal; without this Next would prerender one
// shared copy).
export const dynamic = "force-dynamic";

const s = adminStrings.mod;

export default async function AdminUsersPage({
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

  const list = await getAdminUsers(q, page);
  if (!list) {
    return (
      <EmptyState
        title={adminStrings.readKeyMissing}
        description={adminStrings.readKeyMissingHint}
      />
    );
  }

  const columns: Column<AdminUserRow>[] = [
    {
      key: "who",
      header: adminStrings.nav.users,
      render: (u) => (
        <div className="min-w-0">
          <p className="text-foreground font-medium">{u.fullName}</p>
          <p className="text-muted-foreground font-mono text-xs">
            {u.phone ?? u.email ?? "—"}
          </p>
        </div>
      ),
    },
    { key: "city", header: "Shahar", render: (u) => u.city ?? "—" },
    {
      key: "role",
      header: "Rol",
      render: (u) => (
        <StatusBadge tone="muted">
          {u.role === "employer" ? s.employer : s.seeker}
        </StatusBadge>
      ),
    },
    {
      key: "created",
      header: "Ro'yxatdan",
      className: "whitespace-nowrap",
      render: (u) => formatDate(u.createdAt),
    },
    {
      key: "state",
      header: "Holat",
      render: (u) => (
        <div className="flex flex-wrap gap-1.5">
          {u.suspendedAt ? (
            <StatusBadge tone="destructive">{s.suspended}</StatusBadge>
          ) : (
            <StatusBadge tone="muted">{s.active}</StatusBadge>
          )}
          {u.workerVerifiedAt ? (
            <StatusBadge tone="ok">{s.verified}</StatusBadge>
          ) : null}
        </div>
      ),
    },
    {
      key: "actions",
      header: "Amallar",
      render: (u) => (
        <div className="flex flex-col gap-2">
          <ModerationForm
            action={setProfileSuspended}
            fields={{
              locale,
              id: u.id,
              suspended: u.suspendedAt ? "0" : "1",
            }}
            label={u.suspendedAt ? s.unsuspend : s.suspend}
            withReason={!u.suspendedAt}
          />
          {u.role === "job_seeker" && !u.workerVerifiedAt ? (
            <form action={verifyWorker} className="flex items-center gap-2">
              <input type="hidden" name="locale" value={locale} />
              <input type="hidden" name="id" value={u.id} />
              <select
                name="method"
                className="border-border bg-background text-foreground h-9 rounded-lg border px-2 text-xs"
                defaultValue="manual"
              >
                <option value="manual">{s.methodManual}</option>
                <option value="id_document">{s.methodIdDocument}</option>
              </select>
              <button
                type="submit"
                className="border-border bg-background text-foreground hover:bg-muted h-9 rounded-full border px-3 text-xs font-semibold"
              >
                {s.verify}
              </button>
            </form>
          ) : null}
        </div>
      ),
    },
  ];

  return (
    <div>
      <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-foreground text-2xl font-bold">
          {adminStrings.nav.users}
        </h1>
        <SearchInput defaultValue={q} />
      </div>
      {pick(sp.notice) === "err" ? (
        <ActionNote error={adminStrings.actionFailed} />
      ) : null}
      <DataTable columns={columns} rows={list.rows} rowKey={(u) => u.id} />
      <Pagination
        pathname="/admin/users"
        page={page}
        hasNext={list.hasNext}
        query={q ? { q } : {}}
      />
    </div>
  );
}
