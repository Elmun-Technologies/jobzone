"use client";

import { useTranslations } from "next-intl";
import { useRouter } from "next/navigation";
import { useState } from "react";

import { buttonVariants } from "@/components/ui/button";
import { createClient } from "@/lib/supabase/client";
import { cn } from "@/lib/utils";

import { FormError } from "./auth-fields";

const inputClass =
  "h-11 w-full rounded-lg border border-border bg-background px-3 text-foreground outline-none focus-visible:ring-2 focus-visible:ring-ring";

/** "+998 90 123 45 67" -> "+998901234567"; assumes a leading "+" (required below). */
function normalizePhone(raw: string): string {
  return raw.replace(/[^\d+]/g, "");
}

/**
 * Sign in or up via a one-time code delivered as a Telegram message (Telegram
 * Gateway), not SMS. Supabase's own phone-OTP system generates, stores and
 * verifies the code and mints the session — this only asks it to send one and
 * to check what the visitor typed back. A brand-new phone-only account starts
 * as job_seeker by default, same as Google; creating a company later
 * (createCompany) promotes it to employer, same as the other auth paths.
 */
export function PhoneOtpForm({ next }: { next?: string }) {
  const t = useTranslations("auth");
  const router = useRouter();
  const [phone, setPhone] = useState("");
  const [code, setCode] = useState("");
  const [stage, setStage] = useState<"phone" | "code">("phone");
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | undefined>();

  async function sendCode(e: React.FormEvent) {
    e.preventDefault();
    const normalized = normalizePhone(phone);
    if (!normalized.startsWith("+") || normalized.length < 8) {
      setError(t("errPhoneInvalid"));
      return;
    }
    setPending(true);
    setError(undefined);
    const supabase = createClient();
    const { error: sendError } = await supabase.auth.signInWithOtp({
      phone: normalized,
    });
    setPending(false);
    if (sendError) {
      // Surface the real reason (rate limit, phone auth disabled, SMS-hook /
      // Telegram Gateway failure…) — a generic message here made live
      // misconfiguration undiagnosable from the screen.
      console.error("phone OTP send failed", sendError);
      setError(sendError.message || t("errUnknown"));
      return;
    }
    setPhone(normalized);
    setStage("code");
  }

  async function verifyCode(e: React.FormEvent) {
    e.preventDefault();
    setPending(true);
    setError(undefined);
    const supabase = createClient();
    const { error: verifyError } = await supabase.auth.verifyOtp({
      phone,
      token: code,
      type: "sms",
    });
    setPending(false);
    if (verifyError) {
      console.error("phone OTP verify failed", verifyError);
      // 403 = genuinely wrong/expired code; anything else is operational
      // (rate limit, config) — show the real reason.
      setError(
        verifyError.status === 403
          ? t("errCodeInvalid")
          : verifyError.message || t("errCodeInvalid"),
      );
      return;
    }
    router.push(next || "/account");
    router.refresh();
  }

  if (stage === "phone") {
    return (
      <form onSubmit={sendCode} className="flex flex-col gap-4">
        <label className="block">
          <span className="text-foreground mb-1 block text-sm font-medium">
            {t("phone")}
          </span>
          <input
            type="tel"
            inputMode="tel"
            autoComplete="tel"
            required
            placeholder="+998 90 123 45 67"
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            className={inputClass}
          />
          <span className="text-muted-foreground mt-1 block text-xs">
            {t("phoneHint")}
          </span>
        </label>
        <FormError message={error} />
        <button
          type="submit"
          disabled={pending}
          className={cn(buttonVariants({ variant: "outline", size: "lg" }))}
        >
          {t("sendCode")}
        </button>
      </form>
    );
  }

  return (
    <form onSubmit={verifyCode} className="flex flex-col gap-4">
      <label className="block">
        <span className="text-foreground mb-1 block text-sm font-medium">
          {t("code")}
        </span>
        <input
          type="text"
          inputMode="numeric"
          autoComplete="one-time-code"
          required
          maxLength={8}
          value={code}
          onChange={(e) => setCode(e.target.value)}
          className={inputClass}
        />
        <span className="text-muted-foreground mt-1 block text-xs">
          {t("codeHint", { phone })}
        </span>
      </label>
      <FormError message={error} />
      <button
        type="submit"
        disabled={pending}
        className={cn(buttonVariants({ variant: "primary", size: "lg" }))}
      >
        {t("verifyCode")}
      </button>
      <button
        type="button"
        onClick={() => {
          setStage("phone");
          setCode("");
          setError(undefined);
        }}
        className="text-muted-foreground text-sm hover:underline"
      >
        {t("changeNumber")}
      </button>
    </form>
  );
}
