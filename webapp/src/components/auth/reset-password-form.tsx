"use client";

import { useLocale, useTranslations } from "next-intl";
import { useActionState } from "react";

import { buttonVariants } from "@/components/ui/button";
import {
  updatePasswordAction,
  type AuthFormState,
} from "@/lib/auth/actions";
import { cn } from "@/lib/utils";

import { FormError } from "./auth-fields";

const inputClass =
  "h-11 w-full rounded-lg border border-border bg-background px-3 text-foreground outline-none focus-visible:ring-2 focus-visible:ring-ring";

/** Set-new-password form used at the tail of the recovery flow. */
export function ResetPasswordForm() {
  const t = useTranslations("auth");
  const locale = useLocale();
  const [state, action, pending] = useActionState<AuthFormState, FormData>(
    updatePasswordAction,
    {},
  );

  const errorMsg = state.error
    ? state.error === "weak"
      ? t("errWeak")
      : state.error === "mismatch"
        ? t("errPasswordMismatch")
        : t("errUnknown")
    : undefined;

  return (
    <form action={action} className="flex flex-col gap-4">
      <input type="hidden" name="locale" value={locale} />
      <label className="block">
        <span className="text-foreground mb-1 block text-sm font-medium">
          {t("newPassword")}
        </span>
        <input
          name="password"
          type="password"
          autoComplete="new-password"
          minLength={6}
          required
          className={inputClass}
        />
      </label>
      <label className="block">
        <span className="text-foreground mb-1 block text-sm font-medium">
          {t("confirmPassword")}
        </span>
        <input
          name="confirm"
          type="password"
          autoComplete="new-password"
          minLength={6}
          required
          className={inputClass}
        />
      </label>
      <FormError message={errorMsg} />
      <button
        type="submit"
        disabled={pending}
        className={cn(buttonVariants({ variant: "primary", size: "lg" }))}
      >
        {t("updatePassword")}
      </button>
    </form>
  );
}
