"use client";

import { useTranslations } from "next-intl";
import { useState } from "react";

import { GoogleButton } from "./google-button";
import { PhoneOtpForm } from "./phone-otp-form";
import { SignInForm } from "./sign-in-form";
import { SignUpForm } from "./sign-up-form";

/**
 * Auth methods, one at a time.
 *
 * All three used to render stacked with two "or" dividers between them —
 * three complete forms competing on one screen, which is what made sign-up
 * read as cluttered. Telegram OTP leads (it's the primary path in UZ and
 * matches what mobile offers first), Google sits under it as one tap, and
 * email+password is a text link that swaps the form in. Nothing is removed —
 * only one thing is asked at a time.
 */
export function AuthMethods({
  mode,
  next,
  initialRole,
}: {
  mode: "signIn" | "signUp";
  next?: string;
  initialRole?: string;
}) {
  const t = useTranslations("auth");
  const [emailOpen, setEmailOpen] = useState(false);

  return (
    <div className="flex flex-col gap-4">
      {emailOpen ? (
        <>
          {mode === "signUp" ? (
            <SignUpForm next={next} initialRole={initialRole} />
          ) : (
            <SignInForm next={next} />
          )}
          <button
            type="button"
            onClick={() => setEmailOpen(false)}
            className="text-muted-foreground hover:text-foreground text-sm underline underline-offset-4 transition-colors"
          >
            {t("otherMethods")}
          </button>
        </>
      ) : (
        <>
          <PhoneOtpForm next={next} />

          <div className="text-muted-foreground flex items-center gap-3 text-xs">
            <span className="bg-border h-px flex-1" />
            {t("or")}
            <span className="bg-border h-px flex-1" />
          </div>

          <GoogleButton next={next} />

          <button
            type="button"
            onClick={() => setEmailOpen(true)}
            className="text-muted-foreground hover:text-foreground text-sm underline underline-offset-4 transition-colors"
          >
            {t("continueWithEmail")}
          </button>
        </>
      )}
    </div>
  );
}
