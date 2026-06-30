"use client";

import { useLocale, useTranslations } from "next-intl";
import { useActionState } from "react";

import { buttonVariants } from "@/components/ui/button";
import { createJob, type JobFormState } from "@/lib/actions/employer";
import type { JobCategory } from "@/lib/data/types";
import { cn } from "@/lib/utils";

const inputClass =
  "h-11 w-full rounded-lg border border-border bg-background px-3 text-foreground outline-none focus-visible:ring-2 focus-visible:ring-ring";

const JOB_TYPES = [
  "full_time",
  "part_time",
  "contract",
  "temporary",
  "internship",
  "rotational",
];
const EXPERIENCE = ["entry", "mid", "senior", "lead"];
const WORKING_MODELS = ["onsite", "remote", "hybrid"];

export function PostJobForm({
  companyId,
  categories,
}: {
  companyId: string;
  categories: JobCategory[];
}) {
  const t = useTranslations("employer");
  const tj = useTranslations("jobs");
  const locale = useLocale();
  const [state, action, pending] = useActionState<JobFormState, FormData>(
    createJob,
    {},
  );

  return (
    <form action={action} className="flex flex-col gap-4">
      <input type="hidden" name="locale" value={locale} />
      <input type="hidden" name="companyId" value={companyId} />

      <label className="block">
        <span className="text-foreground mb-1 block text-sm font-medium">
          {t("jobTitle")} *
        </span>
        <input name="title" required className={inputClass} />
      </label>

      <label className="block">
        <span className="text-foreground mb-1 block text-sm font-medium">
          {t("jobDescription")}
        </span>
        <textarea
          name="description"
          rows={6}
          className={cn(inputClass, "h-auto py-2")}
        />
      </label>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <label className="block">
          <span className="text-foreground mb-1 block text-sm font-medium">
            {t("category")}
          </span>
          <select name="categoryId" defaultValue="" className={inputClass}>
            <option value="">—</option>
            {categories.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </label>
        <label className="block">
          <span className="text-foreground mb-1 block text-sm font-medium">
            {t("city")}
          </span>
          <input name="city" className={inputClass} />
        </label>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <label className="block">
          <span className="text-foreground mb-1 block text-sm font-medium">
            {tj("jobType")}
          </span>
          <select name="jobType" defaultValue="" className={inputClass}>
            <option value="">—</option>
            {JOB_TYPES.map((v) => (
              <option key={v} value={v}>
                {tj(`type.${v}`)}
              </option>
            ))}
          </select>
        </label>
        <label className="block">
          <span className="text-foreground mb-1 block text-sm font-medium">
            {tj("workingModel")}
          </span>
          <select name="workingModel" defaultValue="" className={inputClass}>
            <option value="">—</option>
            {WORKING_MODELS.map((v) => (
              <option key={v} value={v}>
                {tj(`model.${v}`)}
              </option>
            ))}
          </select>
        </label>
        <label className="block">
          <span className="text-foreground mb-1 block text-sm font-medium">
            {t("experience")}
          </span>
          <select name="experienceLevel" defaultValue="" className={inputClass}>
            <option value="">—</option>
            {EXPERIENCE.map((v) => (
              <option key={v} value={v}>
                {t(`exp.${v}`)}
              </option>
            ))}
          </select>
        </label>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <label className="block">
          <span className="text-foreground mb-1 block text-sm font-medium">
            {t("salaryMin")}
          </span>
          <input
            name="salaryMin"
            type="number"
            min="0"
            className={inputClass}
          />
        </label>
        <label className="block">
          <span className="text-foreground mb-1 block text-sm font-medium">
            {t("salaryMax")}
          </span>
          <input
            name="salaryMax"
            type="number"
            min="0"
            className={inputClass}
          />
        </label>
        <label className="block">
          <span className="text-foreground mb-1 block text-sm font-medium">
            {t("currency")}
          </span>
          <select name="currency" defaultValue="UZS" className={inputClass}>
            <option value="UZS">UZS</option>
            <option value="USD">USD</option>
          </select>
        </label>
      </div>

      {state.error ? (
        <p className="text-destructive text-sm font-medium">
          {t("errUnknown")}
        </p>
      ) : null}

      <button
        type="submit"
        disabled={pending}
        className={cn(buttonVariants({ variant: "primary", size: "lg" }))}
      >
        {t("publishJob")}
      </button>
    </form>
  );
}
