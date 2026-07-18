"use client";

import { useLocale, useTranslations } from "next-intl";
import { useActionState, useState } from "react";

import { buttonVariants } from "@/components/ui/button";
import { Link } from "@/i18n/navigation";
import { signUpAction, type AuthFormState } from "@/lib/auth/actions";
import { cn } from "@/lib/utils";

import { EmailPasswordFields, FormError } from "./auth-fields";

const ROLES = ["job_seeker", "employer"] as const;

export function SignUpForm({
  next = "",
  initialRole = "job_seeker",
}: {
  next?: string;
  initialRole?: string;
}) {
  const t = useTranslations("auth");
  const locale = useLocale();
  const [role, setRole] = useState<string>(initialRole);
  const [state, action, pending] = useActionState<AuthFormState, FormData>(
    signUpAction,
    {},
  );

  const errorMsg = state.error
    ? state.error === "inUse"
      ? t("errInUse")
      : state.error === "weak"
        ? t("errWeak")
        : state.error === "tos"
          ? t("errTosRequired")
          : t("errUnknown")
    : undefined;

  return (
    <form action={action} className="flex flex-col gap-4">
      <input type="hidden" name="locale" value={locale} />
      <input type="hidden" name="role" value={role} />
      <input type="hidden" name="next" value={next} />

      {/* Role choice */}
      <div className="grid grid-cols-2 gap-2">
        {ROLES.map((r) => (
          <button
            key={r}
            type="button"
            onClick={() => setRole(r)}
            className={cn(
              "rounded-lg border px-3 py-2 text-sm font-medium transition-colors",
              role === r
                ? "border-primary bg-accent text-accent-foreground"
                : "border-border text-foreground hover:bg-muted",
            )}
          >
            {t(`role.${r}`)}
          </button>
        ))}
      </div>

      <EmailPasswordFields
        emailLabel={t("email")}
        passwordLabel={t("password")}
      />
      {/* ToS acceptance — REQUIRED by the browser before the form can
          submit (checkbox has `required`). Real click-to-accept audit trail
          on both stores + a legal-defence line if someone claims they never
          agreed. Links open the /terms and /privacy pages in the current
          locale, in a new tab so the user doesn't lose their form state. */}
      <label className="text-muted-foreground flex items-start gap-2 text-sm">
        <input
          type="checkbox"
          name="tos"
          required
          className="border-border mt-0.5 size-4 shrink-0 rounded"
        />
        <span>
          {t.rich("agreeTos", {
            terms: (chunks) => (
              <Link
                href="/terms"
                target="_blank"
                className="text-primary font-medium hover:underline"
              >
                {chunks}
              </Link>
            ),
            privacy: (chunks) => (
              <Link
                href="/privacy"
                target="_blank"
                className="text-primary font-medium hover:underline"
              >
                {chunks}
              </Link>
            ),
          })}
        </span>
      </label>
      <FormError message={errorMsg} />
      <button
        type="submit"
        disabled={pending}
        className={cn(buttonVariants({ variant: "primary", size: "lg" }))}
      >
        {t("createAccount")}
      </button>
    </form>
  );
}
