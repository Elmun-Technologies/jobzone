import type { Metadata } from "next";

import { ActionNote } from "@/components/admin/action-note";
import { DataTable, type Column } from "@/components/admin/data-table";
import { ModerationForm } from "@/components/admin/moderation-form";
import { Pagination } from "@/components/admin/pagination";
import { ReadKeyMissing } from "@/components/admin/read-key-missing";
import { SearchInput } from "@/components/admin/search-input";
import { StatusBadge } from "@/components/admin/status-badge";
import { getAdminCompanies } from "@/lib/admin/data/companies";
import { adminStrings } from "@/lib/admin/strings";
import { pickParam } from "@/lib/admin/search-params";
import type { AdminCompanyRow } from "@/lib/admin/types";
import {
  setCompanyBlocked,
  unverifyCompany,
  verifyCompany,
} from "@/lib/actions/admin/moderation";
import { requireAdmin } from "@/lib/auth/require-admin";
import { formatDate } from "@/lib/format";

export const metadata: Metadata = { title: adminStrings.nav.companies };

// Session-gated admin page — render per request (the getCurrentUser() try/catch
// swallows the cookies() dynamic signal; without this Next would prerender one
// shared copy).
export const dynamic = "force-dynamic";

const s = adminStrings.mod;

export default async function AdminCompaniesPage({
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

  const list = await getAdminCompanies(q, page);
  if (!list) return <ReadKeyMissing />;

  const columns: Column<AdminCompanyRow>[] = [
    {
      key: "name",
      header: adminStrings.nav.companies,
      render: (c) => <span className="text-foreground font-medium">{c.name}</span>,
    },
    { key: "hq", header: "Manzil", render: (c) => c.headquarters ?? "—" },
    {
      key: "created",
      header: "Yaratilgan",
      className: "whitespace-nowrap",
      render: (c) => formatDate(c.createdAt),
    },
    {
      key: "state",
      header: "Holat",
      render: (c) => (
        <div className="flex flex-wrap gap-1.5">
          {c.isVerified ? (
            <StatusBadge tone="ok">{s.verified}</StatusBadge>
          ) : (
            <StatusBadge tone="muted">{s.unverified}</StatusBadge>
          )}
          {c.blockedAt ? (
            <StatusBadge tone="destructive">{s.blocked}</StatusBadge>
          ) : null}
        </div>
      ),
    },
    {
      key: "actions",
      header: "Amallar",
      render: (c) => (
        <div className="flex flex-col gap-2">
          <ModerationForm
            action={setCompanyBlocked}
            fields={{ locale, id: c.id, blocked: c.blockedAt ? "0" : "1" }}
            label={c.blockedAt ? s.unblock : s.block}
            withReason={!c.blockedAt}
          />
          {!c.isVerified ? (
            <form action={verifyCompany} className="flex items-center gap-2">
              <input type="hidden" name="locale" value={locale} />
              <input type="hidden" name="id" value={c.id} />
              <select
                name="method"
                className="border-border bg-background text-foreground h-9 rounded-lg border px-2 text-xs"
                defaultValue="legal_entity"
              >
                <option value="legal_entity">{s.methodLegalEntity}</option>
                <option value="licensed_agency">{s.methodLicensedAgency}</option>
              </select>
              <button
                type="submit"
                className="border-border bg-background text-foreground hover:bg-muted h-9 rounded-full border px-3 text-xs font-semibold"
              >
                {s.verify}
              </button>
            </form>
          ) : (
            <ModerationForm
              action={unverifyCompany}
              fields={{ locale, id: c.id }}
              label={s.unverify}
              withReason
            />
          )}
        </div>
      ),
    },
  ];

  return (
    <div>
      <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-foreground text-2xl font-bold">
          {adminStrings.nav.companies}
        </h1>
        <SearchInput defaultValue={q} />
      </div>
      {pickParam(sp.notice) === "err" ? (
        <ActionNote error={adminStrings.actionFailed} />
      ) : null}
      <DataTable columns={columns} rows={list.rows} rowKey={(c) => c.id} />
      <Pagination
        pathname="/admin/companies"
        page={page}
        hasNext={list.hasNext}
        query={q ? { q } : {}}
      />
    </div>
  );
}
