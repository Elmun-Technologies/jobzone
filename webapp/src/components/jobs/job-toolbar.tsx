"use client";

import { LayoutGrid, List, Search } from "lucide-react";
import { useTranslations } from "next-intl";
import { usePathname, useRouter, useSearchParams } from "next/navigation";

import { cn } from "@/lib/utils";

/** Search box + sort selector + list/grid view toggle for the jobs page. */
export function JobToolbar() {
  const t = useTranslations("jobs");
  const router = useRouter();
  const pathname = usePathname();
  const params = useSearchParams();

  function update(patch: Record<string, string>) {
    const next = new URLSearchParams(params.toString());
    for (const [key, value] of Object.entries(patch)) {
      if (value) next.set(key, value);
      else next.delete(key);
    }
    router.replace(`${pathname}?${next.toString()}`);
  }

  function onSearch(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const q = new FormData(event.currentTarget).get("q")?.toString() ?? "";
    update({ q });
  }

  const view = params.get("view") === "grid" ? "grid" : "list";

  return (
    <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center">
      <form
        onSubmit={onSearch}
        className="border-border bg-card flex flex-1 items-center gap-2 rounded-full border p-1.5"
      >
        <Search className="text-muted-foreground ml-2 size-5 shrink-0" />
        <input
          name="q"
          defaultValue={params.get("q") ?? ""}
          placeholder={t("searchPlaceholder")}
          aria-label={t("search")}
          className="text-foreground placeholder:text-muted-foreground h-9 w-full flex-1 bg-transparent px-1 outline-none"
        />
      </form>

      <div className="flex items-center gap-2">
        <select
          value={params.get("sort") ?? ""}
          onChange={(e) => update({ sort: e.target.value })}
          aria-label={t("sort")}
          className="border-border bg-background text-foreground focus-visible:ring-ring h-10 rounded-full border px-3 text-sm font-medium focus-visible:ring-2 focus-visible:outline-none"
        >
          <option value="">{t("sortNewest")}</option>
          <option value="salary">{t("sortSalary")}</option>
        </select>

        <div className="border-border flex items-center rounded-full border p-0.5">
          <button
            type="button"
            onClick={() => update({ view: "" })}
            aria-pressed={view === "list"}
            aria-label={t("viewList")}
            className={cn(
              "rounded-full p-1.5 transition-colors",
              view === "list"
                ? "bg-muted text-foreground"
                : "text-muted-foreground",
            )}
          >
            <List className="size-4" />
          </button>
          <button
            type="button"
            onClick={() => update({ view: "grid" })}
            aria-pressed={view === "grid"}
            aria-label={t("viewGrid")}
            className={cn(
              "rounded-full p-1.5 transition-colors",
              view === "grid"
                ? "bg-muted text-foreground"
                : "text-muted-foreground",
            )}
          >
            <LayoutGrid className="size-4" />
          </button>
        </div>
      </div>
    </div>
  );
}
