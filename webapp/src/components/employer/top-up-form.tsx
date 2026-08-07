"use client";

import { useLocale, useTranslations } from "next-intl";
import { useActionState, useEffect, useState } from "react";

import { buttonVariants } from "@/components/ui/button";
import { payTopUp, type TopUpState } from "@/lib/actions/wallet";
import { isValidTopUpAmount } from "@/lib/payments/topup";
import { track } from "@/lib/analytics/track";
import { cn } from "@/lib/utils";

const PRESETS = [50000, 100000, 200000, 500000];

/** Groups digits with regular spaces: 50000 -> "50 000". */
function group(n: number): string {
  return n.toString().replace(/\B(?=(\d{3})+(?!\d))/g, " ");
}

/**
 * Wallet top-up: preset amount chips, a free-amount field, and one button per
 * gateway. Each button submits with its provider; the server action creates the
 * pending credit and redirects to that provider's checkout, and the provider's
 * callback is what completes it. When no gateway is configured the submission
 * still records the request and we show the "awaiting confirmation" note.
 */
export function TopUpForm({
  companyId,
  initialAmount = "",
}: {
  companyId: string;
  /** Pre-fills the amount (digits only), e.g. carried from the promote page's
   * "top up" CTA so the sum the boost needs is already entered. */
  initialAmount?: string;
}) {
  const t = useTranslations("wallet");
  const locale = useLocale();
  const [amount, setAmount] = useState(initialAmount);
  const [state, action, pending] = useActionState<TopUpState, FormData>(
    payTopUp,
    {},
  );
  const amountOk = isValidTopUpAmount(Number(amount));

  // Funnel event — fires exactly when the server confirms the pending
  // top-up. Amount goes as a number so GA4 can aggregate; company_id is
  // safe (non-PII) so cohorts can be split by employer size.
  useEffect(() => {
    if (state.ok) {
      track("wallet_topup_pending", {
        company_id: companyId,
        amount_uzs: Number(amount) || 0,
      });
    }
    // The action returns a fresh `state` object on every submission, so the
    // effect only fires on the transition into ok — no risk of double-firing
    // on re-renders driven by unrelated parent updates.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [state]);

  return (
    <form action={action} className="space-y-4">
      <input type="hidden" name="locale" value={locale} />
      <input type="hidden" name="companyId" value={companyId} />

      <div className="flex flex-wrap gap-2">
        {PRESETS.map((p) => (
          <button
            key={p}
            type="button"
            onClick={() => setAmount(String(p))}
            className={cn(
              "rounded-full border px-4 py-2 text-sm font-medium transition-colors",
              Number(amount) === p
                ? "border-primary bg-primary text-primary-foreground"
                : "border-border hover:border-primary/40",
            )}
          >
            {group(p)}
          </button>
        ))}
      </div>

      <div className="relative">
        <input
          name="amount"
          inputMode="numeric"
          value={amount ? group(Number(amount)) : ""}
          onChange={(e) =>
            setAmount(e.target.value.replace(/\D/g, "").slice(0, 12))
          }
          placeholder={t("amountHint")}
          className="border-border bg-background text-foreground focus-visible:ring-ring h-11 w-full rounded-lg border px-3 pr-12 text-sm outline-none focus-visible:ring-2"
        />
        <span className="text-muted-foreground pointer-events-none absolute inset-y-0 right-3 flex items-center text-sm">
          so&apos;m
        </span>
      </div>

      <div className="grid gap-3">
        {process.env.NEXT_PUBLIC_RAHMAT_ENABLED === "1" ? (
          // Rahmat first when it's on: its hosted checkout covers Uzcard/Humo/
          // Visa/MC/Payme/Click/Uzum in one place. The direct providers stay
          // below as fallbacks — same order as the vacancy pay screen.
          <button
            type="submit"
            name="provider"
            value="rahmat"
            disabled={pending || !amountOk}
            className={cn(buttonVariants({ variant: "primary", size: "lg" }))}
          >
            {t("payWith", { provider: "Rahmat" })}
          </button>
        ) : null}
        <div className="grid gap-3 sm:grid-cols-2">
          <button
            type="submit"
            name="provider"
            value="payme"
            disabled={pending || !amountOk}
            className={cn(
              buttonVariants({
                variant:
                  process.env.NEXT_PUBLIC_RAHMAT_ENABLED === "1"
                    ? "outline"
                    : "primary",
                size: "lg",
              }),
            )}
          >
            {t("payWith", { provider: "Payme" })}
          </button>
          <button
            type="submit"
            name="provider"
            value="click"
            disabled={pending || !amountOk}
            className={cn(buttonVariants({ variant: "outline", size: "lg" }))}
          >
            {t("payWith", { provider: "Click" })}
          </button>
        </div>
      </div>

      {state.ok ? (
        <p className="rounded-lg bg-emerald-50 px-3 py-2 text-sm text-emerald-700 dark:bg-emerald-950 dark:text-emerald-300">
          {t("topUpPending")}
        </p>
      ) : (
        <p className="text-muted-foreground text-center text-xs">
          {t("payNote")}
        </p>
      )}
      {state.error ? (
        <p className="text-destructive text-sm">
          {state.error === "amount" ? t("errAmount") : t("errUnknown")}
        </p>
      ) : null}
    </form>
  );
}
