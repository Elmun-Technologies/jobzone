"use client";

import { useLocale, useTranslations } from "next-intl";
import { useActionState } from "react";

import { buttonVariants } from "@/components/ui/button";
import {
  sendPasswordResetAction,
  type PasswordResetFormState,
} from "@/lib/auth/actions";
import { cn } from "@/lib/utils";

import { FormError } from "./auth-fields";

const inputClass =
  "h-11 w-full rounded-lg border border-border bg-background px-3 text-foreground outline-none focus-visible:ring-2 focus-visible:ring-ring";

/**
 * Recovery-link request form. Shows a permanent "check your email" state on
 * successful submission — including for unknown addresses (see the server
 * action for the enumeration-oracle reasoning).
 */
export function ForgotPasswordForm() {
  const t = useTranslations("auth");
  const locale = useLocale();
  const [state, action, pending] = useActionState<
    PasswordResetFormState,
    FormData
  >(sendPasswordResetAction, {});

  if (state.sent) {
    return (
      <p
        role="status"
        aria-live="polite"
        className="border-primary/30 bg-accent text-accent-foreground rounded-lg border px-3 py-2 text-sm font-medium"
      >
        {t("forgotSent")}
      </p>
    );
  }

  const errorMsg = state.error
    ? state.error === "missing"
      ? t("errMissingEmail")
      : t("errUnknown")
    : undefined;

  return (
    <form action={action} className="flex flex-col gap-4">
      <input type="hidden" name="locale" value={locale} />
      <label className="block">
        <span className="text-foreground mb-1 block text-sm font-medium">
          {t("email")}
        </span>
        <input
          name="email"
          type="email"
          autoComplete="email"
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
        {t("sendResetLink")}
      </button>
    </form>
  );
}
