"use client";

import { useLocale, useTranslations } from "next-intl";
import { useActionState } from "react";

import { buttonVariants } from "@/components/ui/button";
import { applyToJob, type ApplyState } from "@/lib/actions/apply";
import type { ScreeningQuestion } from "@/lib/data/types";
import { cn } from "@/lib/utils";

const fieldClass =
  "w-full rounded-lg border border-border bg-background p-3 text-foreground outline-none focus-visible:ring-2 focus-visible:ring-ring";

export function ApplyForm({
  jobId,
  questions,
}: {
  jobId: string;
  questions: ScreeningQuestion[];
}) {
  const t = useTranslations("apply");
  const locale = useLocale();
  const [state, action, pending] = useActionState<ApplyState, FormData>(
    applyToJob,
    {},
  );

  const errorMsg =
    state.error === "duplicate"
      ? t("errDuplicate")
      : state.error
        ? t("errUnknown")
        : undefined;

  return (
    <form action={action} className="flex flex-col gap-5">
      <input type="hidden" name="jobId" value={jobId} />
      <input type="hidden" name="locale" value={locale} />

      <label className="block">
        <span className="text-foreground mb-1 block text-sm font-medium">
          {t("coverLetter")}{" "}
          <span className="text-muted-foreground">({t("optional")})</span>
        </span>
        <textarea
          name="coverLetter"
          rows={6}
          placeholder={t("coverLetterPlaceholder")}
          className={fieldClass}
        />
      </label>

      {questions.map((q) => (
        <label key={q.id} className="block">
          <span className="text-foreground mb-1 block text-sm font-medium">
            {q.label}
            {q.required ? " *" : ""}
          </span>
          {q.type === "yesno" ? (
            <select
              name={`answer:${q.id}`}
              required={q.required}
              defaultValue=""
              className={cn(fieldClass, "h-11")}
            >
              <option value="" disabled>
                —
              </option>
              <option value="yes">{t("yes")}</option>
              <option value="no">{t("no")}</option>
            </select>
          ) : (
            <input
              name={`answer:${q.id}`}
              type={q.type === "number" ? "number" : "text"}
              required={q.required}
              className={cn(fieldClass, "h-11")}
            />
          )}
        </label>
      ))}

      {errorMsg ? (
        <p className="text-destructive text-sm font-medium">{errorMsg}</p>
      ) : null}

      <button
        type="submit"
        disabled={pending}
        className={cn(buttonVariants({ variant: "primary", size: "lg" }))}
      >
        {t("submit")}
      </button>
    </form>
  );
}
