import type { Metadata } from "next";

import { ActionNote } from "@/components/admin/action-note";
import { ModerationForm } from "@/components/admin/moderation-form";
import { EmptyState } from "@/components/ui/states";
import { getAdminCategories } from "@/lib/admin/data/categories";
import { adminStrings } from "@/lib/admin/strings";
import { setCategoryActive, upsertCategory } from "@/lib/actions/admin/categories";
import { requireAdmin } from "@/lib/auth/require-admin";

export const metadata: Metadata = { title: adminStrings.nav.categories };

// Session-gated admin page — render per request (the getCurrentUser() try/catch
// swallows the cookies() dynamic signal; without this Next would prerender one
// shared copy).
export const dynamic = "force-dynamic";

const s = adminStrings.categories;

const inputClass =
  "border-border bg-background text-foreground placeholder:text-muted-foreground h-9 rounded-lg border px-2.5 text-xs focus-visible:outline-none";

export default async function AdminCategoriesPage({
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

  const categories = await getAdminCategories();
  if (categories === null) {
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
          {adminStrings.nav.categories}
        </h1>
      </div>
      {pick(sp.notice) === "err" ? (
        <ActionNote error={adminStrings.actionFailed} />
      ) : null}

      {/* New category */}
      <div className="border-border bg-card mb-6 rounded-xl border p-4">
        <p className="text-foreground mb-3 text-sm font-semibold">{s.newTitle}</p>
        <form
          action={upsertCategory}
          className="grid grid-cols-2 gap-2 sm:grid-cols-5 sm:items-end"
        >
          <input type="hidden" name="locale" value={locale} />
          <label className="flex flex-col gap-1 text-xs">
            <span className="text-muted-foreground">{s.name}</span>
            <input name="name" required className={inputClass} />
          </label>
          <label className="flex flex-col gap-1 text-xs">
            <span className="text-muted-foreground">{s.slug}</span>
            <input name="slug" required className={inputClass} />
          </label>
          <label className="flex flex-col gap-1 text-xs">
            <span className="text-muted-foreground">{s.icon}</span>
            <input name="icon" className={inputClass} />
          </label>
          <label className="flex flex-col gap-1 text-xs">
            <span className="text-muted-foreground">{s.sortOrder}</span>
            <input
              name="sortOrder"
              type="number"
              defaultValue={categories.length}
              className={inputClass}
            />
          </label>
          <label className="flex flex-col gap-1 text-xs sm:col-span-2">
            <span className="text-muted-foreground">{s.bannerUrl}</span>
            <input name="bannerUrl" type="url" className={inputClass} />
          </label>
          <button
            type="submit"
            className="border-border bg-background text-foreground hover:bg-muted h-9 rounded-full border px-4 text-xs font-semibold"
          >
            {s.add}
          </button>
        </form>
      </div>

      {/* Existing categories */}
      <div className="border-border overflow-x-auto rounded-xl border">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-border bg-muted/50 border-b text-left">
              <th className="text-muted-foreground px-4 py-3 text-xs font-semibold tracking-wide uppercase">
                {s.name}
              </th>
              <th className="text-muted-foreground px-4 py-3 text-xs font-semibold tracking-wide uppercase">
                {s.slug}
              </th>
              <th className="text-muted-foreground px-4 py-3 text-xs font-semibold tracking-wide uppercase">
                {s.icon}
              </th>
              <th className="text-muted-foreground px-4 py-3 text-xs font-semibold tracking-wide uppercase">
                {s.sortOrder}
              </th>
              <th className="text-muted-foreground px-4 py-3 text-xs font-semibold tracking-wide uppercase">
                Amallar
              </th>
            </tr>
          </thead>
          <tbody>
            {categories.length === 0 ? (
              <tr>
                <td colSpan={5} className="px-4 py-8">
                  <EmptyState title={adminStrings.empty} />
                </td>
              </tr>
            ) : (
              categories.map((c) => (
                <tr key={c.id} className="border-border border-b last:border-b-0 align-top">
                  <td className="px-4 py-3" colSpan={4}>
                    <form
                      action={upsertCategory}
                      className="grid grid-cols-2 gap-2 sm:grid-cols-5 sm:items-end"
                    >
                      <input type="hidden" name="locale" value={locale} />
                      <input type="hidden" name="id" value={c.id} />
                      <input type="hidden" name="isActive" value={c.isActive ? "1" : "0"} />
                      <input name="name" defaultValue={c.name} required className={inputClass} />
                      <input name="slug" defaultValue={c.slug} required className={inputClass} />
                      <input name="icon" defaultValue={c.icon ?? ""} className={inputClass} />
                      <label className="flex flex-col gap-1 text-xs">
                        <span className="text-muted-foreground">{s.bannerUrl}</span>
                        <input
                          name="bannerUrl"
                          type="url"
                          defaultValue={c.bannerUrl ?? ""}
                          className={inputClass}
                        />
                      </label>
                      <div className="flex items-center gap-2">
                        <input
                          name="sortOrder"
                          type="number"
                          defaultValue={c.sortOrder}
                          className={`${inputClass} w-20`}
                        />
                        <button
                          type="submit"
                          className="border-border bg-background text-foreground hover:bg-muted h-9 rounded-full border px-3 text-xs font-semibold"
                        >
                          {s.saveChanges}
                        </button>
                      </div>
                    </form>
                  </td>
                  <td className="px-4 py-3">
                    <ModerationForm
                      action={setCategoryActive}
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
