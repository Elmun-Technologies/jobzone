"use client";

import { useLocale, useTranslations } from "next-intl";
import { useActionState, useEffect, useState } from "react";

import { requestTopUp, type TopUpState } from "@/lib/actions/wallet";
import { track } from "@/lib/analytics/track";
import { cn } from "@/lib/utils";

const PRESETS = [50000, 100000, 200000, 500000];

/** Groups digits with regular spaces: 50000 -> "50 000". */
function group(n: number): string {
  return n.toString().replace(/\B(?=(\d{3})+(?!\d))/g, " ");
}

/**
 * Wallet top-up: preset amount chips + a free-amount field. Submitting records a
 * pending top-up request (payments are record-only for now), so on success we
 * show a "pending" note rather than a paid confirmation.
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
    requestTopUp,
    {},
  );

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

      <div className="flex items-stretch gap-2">
        <div className="relative flex-1">
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
        <button
          type="submit"
          disabled={pending}
          className="bg-primary text-primary-foreground h-11 shrink-0 rounded-lg px-5 text-sm font-bold transition-opacity hover:opacity-90 disabled:opacity-60"
        >
          {t("topUp")}
        </button>
      </div>

      {state.ok ? (
        <p className="rounded-lg bg-emerald-50 px-3 py-2 text-sm text-emerald-700 dark:bg-emerald-950 dark:text-emerald-300">
          {t("topUpPending")}
        </p>
      ) : null}
      {state.error ? (
        <p className="text-destructive text-sm">
          {state.error === "amount" ? t("errAmount") : t("errUnknown")}
        </p>
      ) : null}
    </form>
  );
}
