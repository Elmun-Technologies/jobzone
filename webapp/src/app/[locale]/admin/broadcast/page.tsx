import type { Metadata } from "next";

import { ActionNote } from "@/components/admin/action-note";
import { ConfirmSubmit } from "@/components/admin/confirm-submit";
import { EmptyState } from "@/components/ui/states";
import { getBroadcastCounts } from "@/lib/admin/data/broadcast";
import { adminStrings } from "@/lib/admin/strings";
import { sendBroadcast } from "@/lib/actions/admin/broadcast";
import { requireAdmin } from "@/lib/auth/require-admin";
import { groupNumber } from "@/lib/format";

export const metadata: Metadata = { title: adminStrings.nav.broadcast };

// Session-gated admin page — render per request (the getCurrentUser() try/catch
// swallows the cookies() dynamic signal; without this Next would prerender one
// shared copy).
export const dynamic = "force-dynamic";

const s = adminStrings.broadcast;

const inputClass =
  "border-border bg-background text-foreground placeholder:text-muted-foreground w-full rounded-lg border px-3 py-2 text-sm focus-visible:outline-none";

export default async function AdminBroadcastPage({
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

  const counts = await getBroadcastCounts();
  if (!counts) {
    return (
      <EmptyState
        title={adminStrings.readKeyMissing}
        description={adminStrings.readKeyMissingHint}
      />
    );
  }

  const notice = pick(sp.notice);
  const sentCount = Number(pick(sp.count)) || 0;

  const reach = [
    { key: "all", label: s.audienceAll, n: counts.all },
    { key: "seekers", label: s.audienceSeekers, n: counts.seekers },
    { key: "employers", label: s.audienceEmployers, n: counts.employers },
  ];

  return (
    <div className="max-w-2xl">
      <h1 className="text-foreground mb-1 text-2xl font-bold">
        {adminStrings.nav.broadcast}
      </h1>
      <p className="text-muted-foreground mb-5 text-sm">{s.hint}</p>

      {notice === "sent" ? (
        <ActionNote ok={`${groupNumber(sentCount)} ${s.sentCount}`} />
      ) : null}
      {notice === "err" ? <ActionNote error={adminStrings.actionFailed} /> : null}

      {/* Reach summary */}
      <div className="mb-6 grid grid-cols-3 gap-3">
        {reach.map((r) => (
          <div key={r.key} className="border-border bg-card rounded-xl border p-3">
            <p className="text-muted-foreground text-xs">{r.label}</p>
            <p className="text-foreground mt-1 font-mono text-xl font-bold tabular-nums">
              {groupNumber(r.n)}
            </p>
          </div>
        ))}
      </div>

      <form action={sendBroadcast} className="flex flex-col gap-4">
        <input type="hidden" name="locale" value={locale} />
        <label className="flex flex-col gap-1.5">
          <span className="text-foreground text-sm font-medium">{s.title}</span>
          <input name="title" required maxLength={120} className={inputClass} />
        </label>
        <label className="flex flex-col gap-1.5">
          <span className="text-foreground text-sm font-medium">{s.body}</span>
          <textarea name="body" rows={4} maxLength={1000} className={inputClass} />
        </label>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <label className="flex flex-col gap-1.5">
            <span className="text-foreground text-sm font-medium">{s.audience}</span>
            <select name="audience" defaultValue="all" className={inputClass}>
              <option value="all">{s.audienceAll}</option>
              <option value="seekers">{s.audienceSeekers}</option>
              <option value="employers">{s.audienceEmployers}</option>
            </select>
          </label>
          <label className="flex flex-col gap-1.5">
            <span className="text-foreground text-sm font-medium">{s.city}</span>
            <input name="city" placeholder={s.cityHint} className={inputClass} />
          </label>
        </div>
        <div>
          <ConfirmSubmit>{s.send}</ConfirmSubmit>
        </div>
      </form>
    </div>
  );
}
