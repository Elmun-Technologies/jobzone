"use client";

import { Search } from "lucide-react";
import { useTranslations } from "next-intl";
import { usePathname, useRouter, useSearchParams } from "next/navigation";

import { buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";

const JOB_TYPES = [
  "full_time",
  "part_time",
  "contract",
  "temporary",
  "internship",
  "rotational",
];
const WORKING_MODELS = ["on_site", "remote", "hybrid"];

const selectClass =
  "h-11 rounded-lg border border-border bg-background px-3 text-sm text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring";

export function JobSearchControls() {
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

  return (
    <div className="flex flex-col gap-3">
      <form
        onSubmit={onSearch}
        className="border-border bg-card flex items-center gap-2 rounded-full border p-1.5"
      >
        <Search className="text-muted-foreground ml-2 size-5 shrink-0" />
        <input
          name="q"
          defaultValue={params.get("q") ?? ""}
          placeholder={t("searchPlaceholder")}
          className="text-foreground placeholder:text-muted-foreground h-9 flex-1 bg-transparent px-1 outline-none"
        />
        <button
          type="submit"
          className={cn(buttonVariants({ variant: "primary", size: "sm" }))}
        >
          {t("search")}
        </button>
      </form>

      <div className="flex flex-wrap gap-2">
        <select
          aria-label={t("jobType")}
          value={params.get("jobType") ?? ""}
          onChange={(e) => update({ jobType: e.target.value })}
          className={selectClass}
        >
          <option value="">{t("jobType")}</option>
          {JOB_TYPES.map((v) => (
            <option key={v} value={v}>
              {t(`type.${v}`)}
            </option>
          ))}
        </select>

        <select
          aria-label={t("workingModel")}
          value={params.get("workingModel") ?? ""}
          onChange={(e) => update({ workingModel: e.target.value })}
          className={selectClass}
        >
          <option value="">{t("workingModel")}</option>
          {WORKING_MODELS.map((v) => (
            <option key={v} value={v}>
              {t(`model.${v}`)}
            </option>
          ))}
        </select>

        {(params.get("q") ||
          params.get("jobType") ||
          params.get("workingModel")) && (
          <button
            type="button"
            onClick={() => router.replace(pathname)}
            className={cn(buttonVariants({ variant: "ghost", size: "sm" }))}
          >
            {t("clear")}
          </button>
        )}
      </div>
    </div>
  );
}
