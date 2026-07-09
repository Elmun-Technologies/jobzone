import type { Metadata } from "next";

import { ActionNote } from "@/components/admin/action-note";
import { EmptyState } from "@/components/ui/states";
import { getAdminSiteBanner } from "@/lib/admin/data/settings";
import { adminStrings } from "@/lib/admin/strings";
import { setSiteBanner } from "@/lib/actions/admin/settings";
import { requireAdmin } from "@/lib/auth/require-admin";

export const metadata: Metadata = { title: adminStrings.nav.settings };

// Session-gated admin page — render per request (the getCurrentUser() try/catch
// swallows the cookies() dynamic signal; without this Next would prerender one
// shared copy).
export const dynamic = "force-dynamic";

const s = adminStrings.settings;

const inputClass =
  "border-border bg-background text-foreground placeholder:text-muted-foreground w-full rounded-lg border px-3 py-2 text-sm focus-visible:outline-none";

export default async function AdminSettingsPage({
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

  const banner = await getAdminSiteBanner();
  if (!banner) {
    return (
      <EmptyState
        title={adminStrings.readKeyMissing}
        description={adminStrings.readKeyMissingHint}
      />
    );
  }

  const notice = pick(sp.notice);

  return (
    <div className="max-w-2xl">
      <h1 className="text-foreground mb-5 text-2xl font-bold">
        {adminStrings.nav.settings}
      </h1>

      {notice === "saved" ? <ActionNote ok={s.saved} /> : null}
      {notice === "err" ? <ActionNote error={adminStrings.actionFailed} /> : null}

      <div className="border-border bg-card rounded-xl border p-5">
        <h2 className="text-foreground text-lg font-bold">{s.bannerTitle}</h2>
        <p className="text-muted-foreground mt-1 mb-4 text-sm">{s.bannerHint}</p>

        <form action={setSiteBanner} className="flex flex-col gap-4">
          <input type="hidden" name="locale" value={locale} />
          <label className="flex items-center gap-2">
            <input
              type="checkbox"
              name="enabled"
              value="1"
              defaultChecked={banner.enabled}
              className="size-4"
            />
            <span className="text-foreground text-sm font-medium">{s.enabled}</span>
          </label>
          <label className="flex flex-col gap-1.5">
            <span className="text-foreground text-sm font-medium">{s.message}</span>
            <textarea
              name="message"
              rows={3}
              maxLength={300}
              defaultValue={banner.message}
              className={inputClass}
            />
          </label>
          <label className="flex flex-col gap-1.5">
            <span className="text-foreground text-sm font-medium">{s.tone}</span>
            <select name="tone" defaultValue={banner.tone} className={inputClass}>
              <option value="info">{s.toneInfo}</option>
              <option value="warning">{s.toneWarning}</option>
            </select>
          </label>
          <div>
            <button
              type="submit"
              className="bg-primary text-primary-foreground hover:bg-primary/90 rounded-full px-5 py-2 text-sm font-semibold"
            >
              {s.save}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
