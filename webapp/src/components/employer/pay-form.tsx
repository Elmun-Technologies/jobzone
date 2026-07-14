"use client";

import { Check } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { useActionState, useState } from "react";

import { buttonVariants } from "@/components/ui/button";
import { payListing, type PayListingState } from "@/lib/actions/employer";
import { groupNumber } from "@/lib/format";
import { LISTING_TIERS, type ListingTierCode } from "@/lib/listing-tiers";
import { cn } from "@/lib/utils";

/** Tier picker + Payme/Click pay buttons for a draft vacancy. Selecting a tier
 * sets a hidden field; each pay button submits with its provider, and the
 * server action (payListing) creates the order and redirects to the gateway. */
export function PayForm({ jobId }: { jobId: string }) {
  const t = useTranslations("employer.pay");
  const tp = useTranslations("pricing.tiers");
  const locale = useLocale();
  const [state, action, pending] = useActionState<PayListingState, FormData>(
    payListing,
    {},
  );
  // Default to Brend — the nudge tier.
  const [tier, setTier] = useState<ListingTierCode>("brand");

  return (
    <form action={action}>
      <input type="hidden" name="locale" value={locale} />
      <input type="hidden" name="jobId" value={jobId} />
      <input type="hidden" name="tier" value={tier} />

      <ul className="grid gap-3">
        {LISTING_TIERS.map((item) => {
          const selected = item.code === tier;
          return (
            <li key={item.code}>
              <button
                type="button"
                onClick={() => setTier(item.code)}
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

      {state.error ? (
        <p className="text-destructive mt-4 text-sm">
          {t(state.error === "unconfigured" ? "unconfigured" : "error")}
        </p>
      ) : null}

      <div className="mt-6 grid gap-3">
        {process.env.NEXT_PUBLIC_RAHMAT_ENABLED === "1" ? (
          // Rahmat is the primary CTA when enabled — one button opens Rahmat's
          // hosted checkout where the payer picks Uzcard/Humo/Visa/MC/Payme/
          // Click/Uzum. Payme + Click stay below as direct-provider fallbacks.
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
        {t("note")}
      </p>
    </form>
  );
}
