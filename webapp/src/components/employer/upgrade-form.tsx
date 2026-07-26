"use client";

import { Check } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { useActionState, useState } from "react";

import { buttonVariants } from "@/components/ui/button";
import { payListing, type PayListingState } from "@/lib/actions/employer";
import { groupNumber } from "@/lib/format";
import { upgradeTiersFor, type ListingTierCode } from "@/lib/listing-tiers";
import { cn } from "@/lib/utils";

/**
 * Tier picker + pay buttons for a vacancy that is ALREADY LIVE — the upgrade
 * counterpart of PayForm. Only tiers strictly above the listing's current one
 * are offered (the server re-checks: 0075 rejects a same/lower pick), so an
 * employer can never pay twice for visibility they already have. Standard
 * carries no visual treatment, so it never appears here.
 */
export function UpgradeForm({
  jobId,
  currentTier,
}: {
  jobId: string;
  /** `boost_kind` of the live listing — null for free/Standart listings. */
  currentTier: "brand" | "premium" | null;
}) {
  const t = useTranslations("employer.pay");
  const tp = useTranslations("pricing.tiers");
  const tpr = useTranslations("promote");
  const locale = useLocale();
  const [state, action, pending] = useActionState<PayListingState, FormData>(
    payListing,
    {},
  );

  const options = upgradeTiersFor(currentTier);
  const [tier, setTier] = useState<ListingTierCode>(
    // Pre-pick the cheapest step up — the easiest yes.
    options[0]?.code ?? "premium",
  );

  return (
    <form action={action}>
      <input type="hidden" name="locale" value={locale} />
      <input type="hidden" name="jobId" value={jobId} />
      <input type="hidden" name="tier" value={tier} />

      <ul className="grid gap-3">
        {options.map((item) => {
          const selected = item.code === tier;
          return (
            <li key={item.code}>
              <button
                type="button"
                onClick={() => setTier(item.code)}
                aria-pressed={selected}
                className={cn(
                  "flex w-full items-center gap-3 rounded-2xl border p-4 text-left transition-colors",
                  selected
                    ? "border-primary ring-primary/20 bg-accent ring-2"
                    : "border-border bg-card hover:border-primary/40",
                )}
              >
                <span
                  className={cn(
                    "flex size-5 shrink-0 items-center justify-center rounded-full border",
                    selected
                      ? "border-primary bg-primary text-primary-foreground"
                      : "border-border",
                  )}
                >
                  {selected ? <Check className="size-3.5" /> : null}
                </span>
                <span className="flex-1">
                  <span className="text-foreground block font-semibold">
                    {tp(`${item.code}.name`)}
                  </span>
                  <span className="text-muted-foreground block text-sm">
                    {tp(`${item.code}.tagline`)}
                  </span>
                </span>
                <span className="text-foreground font-mono font-bold tabular-nums">
                  {groupNumber(item.priceUzs)}
                  <span className="text-muted-foreground ml-1 text-xs font-semibold">
                    so&apos;m
                  </span>
                </span>
              </button>
            </li>
          );
        })}
      </ul>

      {/* What the chosen tier actually does, so the price has a reason. */}
      <ul className="text-muted-foreground mt-4 space-y-1.5 text-sm">
        {(["f1", "f2", "f3"] as const).map((f) => (
          <li key={f} className="flex items-start gap-2">
            <Check className="text-primary mt-0.5 size-4 shrink-0" />
            <span>{tp(`${tier}.${f}`)}</span>
          </li>
        ))}
      </ul>

      {state.error ? (
        <p className="text-destructive mt-4 text-sm">
          {state.error === "unconfigured"
            ? t("unconfigured")
            : state.error === "notAnUpgrade"
              ? tpr("notAnUpgrade")
              : t("error")}
        </p>
      ) : null}

      <div className="mt-6 grid gap-3">
        {process.env.NEXT_PUBLIC_RAHMAT_ENABLED === "1" ? (
          <button
            type="submit"
            name="provider"
            value="rahmat"
            disabled={pending}
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
            disabled={pending}
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
            disabled={pending}
            className={cn(buttonVariants({ variant: "outline", size: "lg" }))}
          >
            {t("payWith", { provider: "Click" })}
          </button>
        </div>
      </div>
      <p className="text-muted-foreground mt-3 text-center text-xs">
        {tpr("upgradeNote")}
      </p>
    </form>
  );
}
