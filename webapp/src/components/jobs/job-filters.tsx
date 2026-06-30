"use client";

import { SlidersHorizontal, X } from "lucide-react";
import { useTranslations } from "next-intl";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useState } from "react";

import { cn } from "@/lib/utils";

const JOB_TYPES = [
  "full_time",
  "part_time",
  "contract",
  "temporary",
  "internship",
  "rotational",
];
const WORKING_MODELS = ["onsite", "remote", "hybrid"];
const EXPERIENCE = ["entry", "mid", "senior", "lead"];
const POSTED = [
  { value: "1", key: "last24h" },
  { value: "3", key: "last3days" },
  { value: "7", key: "last7days" },
  { value: "30", key: "last30days" },
];

// Params this panel owns — "Clear" resets exactly these (keeps q + category).
const OWNED = [
  "workingModel",
  "jobType",
  "experienceLevel",
  "city",
  "salaryMin",
  "currency",
  "postedWithin",
];

export function JobFilters({ cities }: { cities: string[] }) {
  const t = useTranslations("jobs");
  const router = useRouter();
  const pathname = usePathname();
  const params = useSearchParams();
  const [open, setOpen] = useState(false);

  function update(patch: Record<string, string>) {
    const next = new URLSearchParams(params.toString());
    for (const [key, value] of Object.entries(patch)) {
      if (value) next.set(key, value);
      else next.delete(key);
    }
    router.replace(`${pathname}?${next.toString()}`);
  }

  /** Toggles a single-select param: clicking the active value clears it. */
  function toggle(key: string, value: string) {
    update({ [key]: params.get(key) === value ? "" : value });
  }

  function clearAll() {
    update(Object.fromEntries(OWNED.map((k) => [k, ""])));
  }

  const currency = params.get("currency") ?? "UZS";
  const activeCount = OWNED.filter((k) => params.get(k)).length;

  return (
    <div className="border-border bg-card rounded-2xl border p-4">
      <div className="flex items-center justify-between">
        <h2 className="text-foreground flex items-center gap-2 font-semibold">
          <SlidersHorizontal className="size-4" />
          {t("filters")}
          {activeCount > 0 ? (
            <span className="bg-primary text-primary-foreground rounded-full px-1.5 text-xs font-bold">
              {activeCount}
            </span>
          ) : null}
        </h2>
        <div className="flex items-center gap-2">
          {activeCount > 0 ? (
            <button
              type="button"
              onClick={clearAll}
              className="text-primary inline-flex items-center gap-1 text-sm font-medium hover:underline"
            >
              <X className="size-3.5" />
              {t("clear")}
            </button>
          ) : null}
          <button
            type="button"
            onClick={() => setOpen((o) => !o)}
            aria-expanded={open}
            className="border-border rounded-full border px-3 py-1 text-sm lg:hidden"
          >
            {open ? t("clear") : t("filters")}
          </button>
        </div>
      </div>

      <div className={cn("mt-4 space-y-5", open ? "block" : "hidden lg:block")}>
        <ChipGroup
          label={t("workingModel")}
          active={params.get("workingModel")}
          options={WORKING_MODELS.map((v) => ({
            value: v,
            label: t(`model.${v}`),
          }))}
          onToggle={(v) => toggle("workingModel", v)}
        />

        <ChipGroup
          label={t("jobType")}
          active={params.get("jobType")}
          options={JOB_TYPES.map((v) => ({ value: v, label: t(`type.${v}`) }))}
          onToggle={(v) => toggle("jobType", v)}
        />

        <ChipGroup
          label={t("experience")}
          active={params.get("experienceLevel")}
          options={EXPERIENCE.map((v) => ({
            value: v,
            label: t(`exp.${v}`),
          }))}
          onToggle={(v) => toggle("experienceLevel", v)}
        />

        {cities.length > 0 ? (
          <div>
            <p className="text-muted-foreground mb-2 text-sm font-medium">
              {t("region")}
            </p>
            <select
              value={params.get("city") ?? ""}
              onChange={(e) => update({ city: e.target.value })}
              aria-label={t("region")}
              className="border-border bg-background text-foreground focus-visible:ring-ring h-10 w-full rounded-lg border px-3 text-sm focus-visible:ring-2 focus-visible:outline-none"
            >
              <option value="">{t("allRegions")}</option>
              {cities.map((c) => (
                <option key={c} value={c}>
                  {c}
                </option>
              ))}
            </select>
          </div>
        ) : null}

        <div>
          <div className="mb-2 flex items-center justify-between">
            <p className="text-muted-foreground text-sm font-medium">
              {t("salary")}
            </p>
            <div className="bg-muted inline-flex items-center rounded-full p-0.5 text-xs font-semibold">
              {["UZS", "USD"].map((c) => (
                <button
                  key={c}
                  type="button"
                  onClick={() => update({ currency: c === "UZS" ? "" : c })}
                  className={cn(
                    "rounded-full px-2.5 py-1 transition-colors",
                    currency === c
                      ? "bg-background text-foreground shadow-sm"
                      : "text-muted-foreground",
                  )}
                >
                  {c}
                </button>
              ))}
            </div>
          </div>
          <input
            type="number"
            inputMode="numeric"
            min={0}
            defaultValue={params.get("salaryMin") ?? ""}
            placeholder={t("salaryMin")}
            aria-label={t("salaryMin")}
            onBlur={(e) => update({ salaryMin: e.target.value.trim() })}
            onKeyDown={(e) => {
              if (e.key === "Enter")
                update({ salaryMin: e.currentTarget.value.trim() });
            }}
            className="border-border bg-background text-foreground placeholder:text-muted-foreground focus-visible:ring-ring h-10 w-full rounded-lg border px-3 text-sm focus-visible:ring-2 focus-visible:outline-none"
          />
        </div>

        <ChipGroup
          label={t("postedWithin")}
          active={params.get("postedWithin")}
          options={POSTED.map((p) => ({ value: p.value, label: t(p.key) }))}
          onToggle={(v) => toggle("postedWithin", v)}
        />
      </div>
    </div>
  );
}

function ChipGroup({
  label,
  active,
  options,
  onToggle,
}: {
  label: string;
  active: string | null;
  options: { value: string; label: string }[];
  onToggle: (value: string) => void;
}) {
  return (
    <div>
      <p className="text-muted-foreground mb-2 text-sm font-medium">{label}</p>
      <div className="flex flex-wrap gap-2">
        {options.map((o) => {
          const on = active === o.value;
          return (
            <button
              key={o.value}
              type="button"
              aria-pressed={on}
              onClick={() => onToggle(o.value)}
              className={cn(
                "rounded-full border px-3 py-1.5 text-sm font-medium transition-colors",
                on
                  ? "border-primary bg-primary text-primary-foreground"
                  : "border-border bg-background text-foreground hover:border-primary/40",
              )}
            >
              {o.label}
            </button>
          );
        })}
      </div>
    </div>
  );
}
