"use client";

import { Check, Sparkles, TrendingUp } from "lucide-react";
import { useActionState, useState } from "react";
import { useTranslations } from "next-intl";

import { buttonVariants } from "@/components/ui/button";
import { promoteJob, type JobFormState } from "@/lib/actions/employer";
import type { PromotionProduct } from "@/lib/data/pricing";
import { groupNumber } from "@/lib/format";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

/**
 * Package picker for boosting (reklama) one live vacancy from the Hamyon
 * balance. Cards are single-select; the chosen product's code rides a hidden
 * field to the promoteJob action. When the balance can't cover the pick, the
 * submit is swapped for a top-up link (and the RPC is the backstop if a race
 * slips through — surfaced as `insufficientFunds`).
 */
export function PromotePicker({
  jobId,
  locale,
  products,
  balanceUzs,
}: {
  jobId: string;
  locale: string;
  products: PromotionProduct[];
  balanceUzs: number;
}) {
  const t = useTranslations("promote");
  const [selected, setSelected] = useState<string>(products[0]?.code ?? "");
  const [state, action, pending] = useActionState<JobFormState, FormData>(
    promoteJob,
    {},
  );

  const active = products.find((p) => p.code === selected) ?? products[0];
  const affordable = active ? balanceUzs >= active.priceUzs : false;

  return (
    <form action={action} className="space-y-4">
      <input type="hidden" name="locale" value={locale} />
      <input type="hidden" name="jobId" value={jobId} />
      <input type="hidden" name="productCode" value={selected} />

      <ul className="grid gap-3 sm:grid-cols-2">
        {products.map((p) => {
          const isSel = p.code === selected;
          const Icon = p.kind === "featured" ? Sparkles : TrendingUp;
          return (
            <li key={p.code}>
              <button
                type="button"
                onClick={() => setSelected(p.code)}
                aria-pressed={isSel}
                className={cn(
                  "flex w-full flex-col gap-1 rounded-2xl border p-4 text-left transition-colors",
                  isSel
                    ? "border-primary ring-primary/40 bg-accent ring-2"
                    : "border-border bg-card hover:border-primary/40",
                )}
              >
                <span className="flex items-center gap-2">
                  <Icon className="text-primary size-4" />
                  <span className="text-foreground font-semibold">
                    {p.name}
                  </span>
                  {isSel ? (
                    <Check className="text-primary ml-auto size-4" />
                  ) : null}
                </span>
                {p.description ? (
                  <span className="text-muted-foreground text-sm">
                    {p.description}
                  </span>
                ) : null}
                <span className="mt-1 flex items-baseline justify-between gap-2">
                  <span className="text-foreground font-mono text-lg font-bold tabular-nums">
                    {groupNumber(p.priceUzs)}{" "}
                    <span className="text-muted-foreground text-sm">
                      so&apos;m
                    </span>
                  </span>
                  <span className="text-muted-foreground text-xs">
                    {t("duration", { days: p.durationDays })}
                  </span>
                </span>
              </button>
            </li>
          );
        })}
      </ul>

      <div className="border-border bg-card flex items-center justify-between rounded-xl border px-4 py-3 text-sm">
        <span className="text-muted-foreground">{t("balance")}</span>
        <span className="text-foreground font-mono font-semibold tabular-nums">
          {groupNumber(balanceUzs)} so&apos;m
        </span>
      </div>

      {state.insufficientFunds ? (
        <div className="rounded-xl border border-amber-300 bg-amber-50 p-4 text-sm dark:border-amber-800 dark:bg-amber-950/40">
          <p className="font-medium text-amber-900 dark:text-amber-200">
            {t("insufficientTitle")}
          </p>
          <p className="mt-1 text-amber-800 dark:text-amber-300">
            {t("insufficientHint")}
          </p>
        </div>
      ) : null}

      {state.error ? (
        <p className="text-sm text-red-600 dark:text-red-400">
          {t("errUnknown")}
          {state.detail ? (
            <span className="mt-1 block font-mono text-xs opacity-70">
              {state.detail}
            </span>
          ) : null}
        </p>
      ) : null}

      {affordable ? (
        <button
          type="submit"
          disabled={pending || !active}
          className={cn(buttonVariants({ variant: "primary" }), "w-full")}
        >
          {pending
            ? t("buying")
            : t("buyFor", {
                price: `${groupNumber(active?.priceUzs ?? 0)} so'm`,
              })}
        </button>
      ) : (
        <Link
          href="/employer/wallet"
          className={cn(buttonVariants({ variant: "primary" }), "w-full")}
        >
          {t("topUp")}
        </Link>
      )}
    </form>
  );
}
