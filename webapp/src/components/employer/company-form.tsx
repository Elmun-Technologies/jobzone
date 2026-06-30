"use client";

import { useLocale, useTranslations } from "next-intl";
import { useActionState } from "react";

import { buttonVariants } from "@/components/ui/button";
import type { CompanyFormState } from "@/lib/actions/employer";
import { cn } from "@/lib/utils";

const inputClass =
  "h-11 w-full rounded-lg border border-border bg-background px-3 text-foreground outline-none focus-visible:ring-2 focus-visible:ring-ring";

export interface CompanyInitial {
  id?: string;
  name?: string;
  about?: string | null;
  industry?: string | null;
  website?: string | null;
  headquarters?: string | null;
}

/** Shared create/edit company form. `action` is the matching Server Action. */
export function CompanyForm({
  action,
  initial,
  submitLabel,
}: {
  action: (
    prev: CompanyFormState,
    formData: FormData,
  ) => Promise<CompanyFormState>;
  initial?: CompanyInitial;
  submitLabel: string;
}) {
  const t = useTranslations("employer");
  const locale = useLocale();
  const [state, formAction, pending] = useActionState<
    CompanyFormState,
    FormData
  >(action, {});

  return (
    <form action={formAction} className="flex flex-col gap-4">
      <input type="hidden" name="locale" value={locale} />
      {initial?.id ? (
        <input type="hidden" name="companyId" value={initial.id} />
      ) : null}

      <label className="block">
        <span className="text-foreground mb-1 block text-sm font-medium">
          {t("companyName")} *
        </span>
        <input
          name="name"
          required
          defaultValue={initial?.name ?? ""}
          className={inputClass}
        />
      </label>

      <label className="block">
        <span className="text-foreground mb-1 block text-sm font-medium">
          {t("companyAbout")}
        </span>
        <textarea
          name="about"
          rows={4}
          defaultValue={initial?.about ?? ""}
          className={cn(inputClass, "h-auto py-2")}
        />
      </label>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <label className="block">
          <span className="text-foreground mb-1 block text-sm font-medium">
            {t("industry")}
          </span>
          <input
            name="industry"
            defaultValue={initial?.industry ?? ""}
            className={inputClass}
          />
        </label>
        <label className="block">
          <span className="text-foreground mb-1 block text-sm font-medium">
            {t("headquarters")}
          </span>
          <input
            name="headquarters"
            defaultValue={initial?.headquarters ?? ""}
            className={inputClass}
          />
        </label>
      </div>

      <label className="block">
        <span className="text-foreground mb-1 block text-sm font-medium">
          {t("website")}
        </span>
        <input
          name="website"
          type="url"
          defaultValue={initial?.website ?? ""}
          className={inputClass}
        />
      </label>

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
        {submitLabel}
      </button>
    </form>
  );
}
