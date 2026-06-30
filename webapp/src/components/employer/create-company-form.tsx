"use client";

import { useLocale, useTranslations } from "next-intl";
import { useActionState } from "react";

import { buttonVariants } from "@/components/ui/button";
import { createCompany, type CompanyFormState } from "@/lib/actions/employer";
import { cn } from "@/lib/utils";

const inputClass =
  "h-11 w-full rounded-lg border border-border bg-background px-3 text-foreground outline-none focus-visible:ring-2 focus-visible:ring-ring";

export function CreateCompanyForm() {
  const t = useTranslations("employer");
  const locale = useLocale();
  const [state, action, pending] = useActionState<CompanyFormState, FormData>(
    createCompany,
    {},
  );

  return (
    <form action={action} className="flex flex-col gap-4">
      <input type="hidden" name="locale" value={locale} />

      <label className="block">
        <span className="text-foreground mb-1 block text-sm font-medium">
          {t("companyName")} *
        </span>
        <input name="name" required className={inputClass} />
      </label>

      <label className="block">
        <span className="text-foreground mb-1 block text-sm font-medium">
          {t("companyAbout")}
        </span>
        <textarea
          name="about"
          rows={4}
          className={cn(inputClass, "h-auto py-2")}
        />
      </label>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <label className="block">
          <span className="text-foreground mb-1 block text-sm font-medium">
            {t("industry")}
          </span>
          <input name="industry" className={inputClass} />
        </label>
        <label className="block">
          <span className="text-foreground mb-1 block text-sm font-medium">
            {t("headquarters")}
          </span>
          <input name="headquarters" className={inputClass} />
        </label>
      </div>

      <label className="block">
        <span className="text-foreground mb-1 block text-sm font-medium">
          {t("website")}
        </span>
        <input name="website" type="url" className={inputClass} />
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
        {t("createCompany")}
      </button>
    </form>
  );
}
