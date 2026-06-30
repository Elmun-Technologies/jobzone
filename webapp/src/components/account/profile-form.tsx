"use client";

import { useLocale, useTranslations } from "next-intl";
import { useActionState } from "react";

import { buttonVariants } from "@/components/ui/button";
import { updateProfile, type ProfileFormState } from "@/lib/actions/profile";
import type { ProfileDetails } from "@/lib/data/profile";
import { cn } from "@/lib/utils";

const inputClass =
  "h-11 w-full rounded-lg border border-border bg-background px-3 text-foreground outline-none focus-visible:ring-2 focus-visible:ring-ring";

function Field({
  name,
  label,
  value,
  type = "text",
}: {
  name: string;
  label: string;
  value: string;
  type?: string;
}) {
  return (
    <label className="block">
      <span className="mb-1 block text-sm font-medium text-foreground">
        {label}
      </span>
      <input
        name={name}
        type={type}
        defaultValue={value}
        className={inputClass}
      />
    </label>
  );
}

export function ProfileForm({ initial }: { initial: ProfileDetails }) {
  const t = useTranslations("profile");
  const locale = useLocale();
  const [state, action, pending] = useActionState<ProfileFormState, FormData>(
    updateProfile,
    {},
  );

  return (
    <form action={action} className="flex flex-col gap-4">
      <input type="hidden" name="locale" value={locale} />

      <Field name="fullName" label={t("fullName")} value={initial.fullName} />
      <Field name="headline" label={t("headline")} value={initial.headline} />

      <label className="block">
        <span className="mb-1 block text-sm font-medium text-foreground">
          {t("bio")}
        </span>
        <textarea
          name="bio"
          rows={4}
          defaultValue={initial.bio}
          className={cn(inputClass, "h-auto py-2")}
        />
      </label>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <Field
          name="phone"
          label={t("phone")}
          value={initial.phone}
          type="tel"
        />
        <Field name="city" label={t("city")} value={initial.city} />
        <Field name="country" label={t("country")} value={initial.country} />
      </div>

      {state.error ? (
        <p className="text-sm font-medium text-destructive">{t("errUnknown")}</p>
      ) : null}

      <button
        type="submit"
        disabled={pending}
        className={cn(buttonVariants({ variant: "primary", size: "lg" }))}
      >
        {t("save")}
      </button>
    </form>
  );
}
