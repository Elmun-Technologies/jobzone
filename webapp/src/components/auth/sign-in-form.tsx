"use client";

import { useLocale, useTranslations } from "next-intl";
import { useActionState } from "react";

import { buttonVariants } from "@/components/ui/button";
import { Link } from "@/i18n/navigation";
import { signInAction, type AuthFormState } from "@/lib/auth/actions";
import { cn } from "@/lib/utils";

import { EmailPasswordFields, FormError } from "./auth-fields";

export function SignInForm({ next = "" }: { next?: string }) {
  const t = useTranslations("auth");
  const locale = useLocale();
  const [state, action, pending] = useActionState<AuthFormState, FormData>(
    signInAction,
    {},
  );

  const errorMsg = state.error
    ? state.error === "invalid"
      ? t("errInvalid")
      : t("errUnknown")
    : undefined;

  return (
    <form action={action} className="flex flex-col gap-4">
      <input type="hidden" name="locale" value={locale} />
      <input type="hidden" name="next" value={next} />
      <EmailPasswordFields
        emailLabel={t("email")}
        passwordLabel={t("password")}
      />
      <div className="-mt-2 flex justify-end">
        <Link
          href="/forgot-password"
          className="text-muted-foreground hover:text-primary text-sm font-medium"
        >
          {t("forgotPassword")}
        </Link>
      </div>
      <FormError message={errorMsg} />
      <button
        type="submit"
        disabled={pending}
        className={cn(buttonVariants({ variant: "primary", size: "lg" }))}
      >
        {t("signIn")}
      </button>
    </form>
  );
}
