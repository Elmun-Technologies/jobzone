import type { Metadata } from "next";

import { ActionNote } from "@/components/admin/action-note";
import { ModerationForm } from "@/components/admin/moderation-form";
import { EmptyState } from "@/components/ui/states";
import { getAdminCategories } from "@/lib/admin/data/categories";
import { getAdminTelegramChannels } from "@/lib/admin/data/telegram-channels";
import { adminStrings } from "@/lib/admin/strings";
import {
  setTelegramChannelActive,
  upsertTelegramChannel,
} from "@/lib/actions/admin/telegram-channels";
import { requireAdmin } from "@/lib/auth/require-admin";
import { UZ_REGIONS } from "@/lib/uz-regions";

export const metadata: Metadata = { title: adminStrings.nav.telegramChannels };

// Session-gated admin page — render per request (see categories/page.tsx).
export const dynamic = "force-dynamic";

const s = adminStrings.telegramChannels;

const inputClass =
  "border-border bg-background text-foreground placeholder:text-muted-foreground h-9 rounded-lg border px-2.5 text-xs focus-visible:outline-none";

export default async function AdminTelegramChannelsPage({
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

  const [channels, categories] = await Promise.all([
    getAdminTelegramChannels(),
    getAdminCategories(),
  ]);
  if (channels === null || categories === null) {
    return (
      <EmptyState
        title={adminStrings.readKeyMissing}
        description={adminStrings.readKeyMissingHint}
      />
    );
  }

  return (
    <div>
      <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-foreground text-2xl font-bold">
          {adminStrings.nav.telegramChannels}
        </h1>
      </div>
      <p className="text-muted-foreground mb-5 max-w-2xl text-xs">{s.hint}</p>
      {pick(sp.notice) === "err" ? (
        <ActionNote error={adminStrings.actionFailed} />
      ) : null}

      {/* New mapping */}
      <div className="border-border bg-card mb-6 rounded-xl border p-4">
        <p className="text-foreground mb-3 text-sm font-semibold">{s.newTitle}</p>
        <form
          action={upsertTelegramChannel}
          className="grid grid-cols-2 gap-2 sm:grid-cols-5 sm:items-end"
        >
          <input type="hidden" name="locale" value={locale} />
          <label className="flex flex-col gap-1 text-xs">
            <span className="text-muted-foreground">{s.category}</span>
            <select name="categoryId" required className={inputClass}>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </label>
          <label className="flex flex-col gap-1 text-xs">
            <span className="text-muted-foreground">{s.region}</span>
            <select name="region" defaultValue="" className={inputClass}>
              <option value="">{s.allRegions}</option>
              {UZ_REGIONS.map((r) => (
                <option key={r} value={r}>
                  {r}
                </option>
              ))}
            </select>
          </label>
          <label className="flex flex-col gap-1 text-xs">
            <span className="text-muted-foreground">{s.chatId}</span>
            <input name="chatId" required className={inputClass} />
          </label>
          <label className="flex flex-col gap-1 text-xs">
            <span className="text-muted-foreground">{s.title}</span>
            <input name="title" className={inputClass} />
          </label>
          <button
            type="submit"
            className="border-border bg-background text-foreground hover:bg-muted h-9 rounded-full border px-4 text-xs font-semibold"
          >
            {s.add}
          </button>
        </form>
      </div>

      {/* Existing mappings */}
      <div className="border-border overflow-x-auto rounded-xl border">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-border bg-muted/50 border-b text-left">
              <th className="text-muted-foreground px-4 py-3 text-xs font-semibold tracking-wide uppercase">
                {s.category}
              </th>
              <th className="text-muted-foreground px-4 py-3 text-xs font-semibold tracking-wide uppercase">
                {s.region}
              </th>
              <th className="text-muted-foreground px-4 py-3 text-xs font-semibold tracking-wide uppercase">
                {s.chatId}
              </th>
              <th className="text-muted-foreground px-4 py-3 text-xs font-semibold tracking-wide uppercase">
                Amallar
              </th>
            </tr>
          </thead>
          <tbody>
            {channels.length === 0 ? (
              <tr>
                <td colSpan={4} className="px-4 py-8">
                  <EmptyState title={adminStrings.empty} />
                </td>
              </tr>
            ) : (
              channels.map((c) => (
                <tr key={c.id} className="border-border border-b last:border-b-0 align-top">
                  <td className="px-4 py-3">
                    <p className="text-foreground font-medium">{c.categoryName}</p>
                    {c.title ? (
                      <p className="text-muted-foreground text-xs">{c.title}</p>
                    ) : null}
                  </td>
                  <td className="px-4 py-3">{c.region ?? s.allRegions}</td>
                  <td className="px-4 py-3">{c.chatId}</td>
                  <td className="px-4 py-3">
                    <ModerationForm
                      action={setTelegramChannelActive}
                      fields={{ locale, id: c.id, active: c.isActive ? "0" : "1" }}
                      label={c.isActive ? s.deactivate : s.activate}
                    />
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
