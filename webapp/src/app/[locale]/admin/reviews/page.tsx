import type { Metadata } from "next";

import { ActionNote } from "@/components/admin/action-note";
import { DataTable, type Column } from "@/components/admin/data-table";
import { ModerationForm } from "@/components/admin/moderation-form";
import { Pagination } from "@/components/admin/pagination";
import { StatusBadge } from "@/components/admin/status-badge";
import { buttonVariants } from "@/components/ui/button";
import { EmptyState } from "@/components/ui/states";
import { getAdminReviews, type ReviewKind } from "@/lib/admin/data/reviews";
import { adminStrings } from "@/lib/admin/strings";
import type { AdminReviewRow } from "@/lib/admin/types";
import { setReviewHidden } from "@/lib/actions/admin/moderation";
import { requireAdmin } from "@/lib/auth/require-admin";
import { formatDate } from "@/lib/format";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

export const metadata: Metadata = { title: adminStrings.nav.reviews };

// Session-gated admin page — render per request (the getCurrentUser() try/catch
// swallows the cookies() dynamic signal; without this Next would prerender one
// shared copy).
export const dynamic = "force-dynamic";

const s = adminStrings.mod;

export default async function AdminReviewsPage({
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
  const tab: ReviewKind = pick(sp.tab) === "worker" ? "worker" : "company";
  const page = Math.max(1, Number(pick(sp.page)) || 1);

  const list = await getAdminReviews(tab, page);
  if (!list) {
    return (
      <EmptyState
        title={adminStrings.readKeyMissing}
        description={adminStrings.readKeyMissingHint}
      />
    );
  }

  const columns: Column<AdminReviewRow>[] = [
    {
      key: "subject",
      header: tab === "company" ? adminStrings.nav.companies : adminStrings.nav.users,
      render: (r) => <span className="text-foreground font-medium">{r.subject}</span>,
    },
    { key: "author", header: "Muallif", render: (r) => r.authorName },
    {
      key: "rating",
      header: "Baho",
      render: (r) => (
        <span className="font-mono text-xs tabular-nums">{r.rating}/5</span>
      ),
    },
    {
      key: "body",
      header: "Matn",
      className: "max-w-sm",
      render: (r) => (
        <p className="text-muted-foreground line-clamp-2 text-xs">{r.body ?? "—"}</p>
      ),
    },
    {
      key: "created",
      header: "Sana",
      className: "whitespace-nowrap",
      render: (r) => formatDate(r.createdAt),
    },
    {
      key: "state",
      header: "Holat",
      render: (r) =>
        r.hiddenAt ? (
          <StatusBadge tone="destructive">{s.hidden}</StatusBadge>
        ) : (
          <StatusBadge tone="ok">{s.active}</StatusBadge>
        ),
    },
    {
      key: "actions",
      header: "Amallar",
      render: (r) => (
        <ModerationForm
          action={setReviewHidden}
          fields={{ locale, id: r.id, kind: tab, hidden: r.hiddenAt ? "0" : "1" }}
          label={r.hiddenAt ? s.show : s.hide}
          withReason={!r.hiddenAt}
        />
      ),
    },
  ];

  return (
    <div>
      <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-foreground text-2xl font-bold">
          {adminStrings.nav.reviews}
        </h1>
        <div className="flex gap-2">
          {(
            [
              ["company", s.companyReviews],
              ["worker", s.workerReviews],
            ] as const
          ).map(([kind, label]) => (
            <Link
              key={kind}
              href={{
                pathname: "/admin/reviews",
                query: kind === "company" ? {} : { tab: kind },
              }}
              className={cn(
                buttonVariants({
                  variant: tab === kind ? "primary" : "outline",
                  size: "sm",
                }),
              )}
            >
              {label}
            </Link>
          ))}
        </div>
      </div>
      {pick(sp.notice) === "err" ? (
        <ActionNote error={adminStrings.actionFailed} />
      ) : null}
      <DataTable columns={columns} rows={list.rows} rowKey={(r) => r.id} />
      <Pagination
        pathname="/admin/reviews"
        page={page}
        hasNext={list.hasNext}
        query={tab === "worker" ? { tab } : {}}
      />
    </div>
  );
}
