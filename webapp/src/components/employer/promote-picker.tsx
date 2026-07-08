"use client";

import { ArrowUp, Check, Sparkles, TrendingUp } from "lucide-react";
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
 * balance — designed to sell: the best per-day value is badged and pre-picked,
 * every card shows a per-day price, and a mini "after promotion" preview makes
 * the payoff concrete. Cards are single-select; the chosen product's code rides
 * a hidden field to the promoteJob action. When the balance can't cover the
 * pick, the CTA becomes a top-up link that carries the exact amount needed (so
 * the wallet page opens pre-filled); the RPC is the backstop if a race slips
 * through (surfaced as `insufficientFunds`).
 */
export function PromotePicker({
  jobId,
  jobTitle,
  locale,
  products,
  balanceUzs,
}: {
  jobId: string;
  jobTitle: string;
  locale: string;
  products: PromotionProduct[];
  balanceUzs: number;
}) {
  const t = useTranslations("promote");
  const perDay = (p: PromotionProduct) =>
    p.priceUzs / Math.max(p.durationDays, 1);
  // Best value = lowest cost per day. Badge it and pre-select it (a gentle
  // nudge toward the package that gives the most visibility per so'm).
  const bestCode = products.length
    ? products.reduce((a, b) => (perDay(b) < perDay(a) ? b : a)).code
    : "";
  // How much cheaper per day each TOP tier is vs the priciest TOP tier — so a
  // longer package visibly rewards ("14% cheaper"). Featured is a different
  // benefit, so it's left out of the comparison.
  const maxTopPerDay = products
    .filter((p) => p.kind === "top")
    .reduce((m, p) => Math.max(m, perDay(p)), 0);
  const savingsOf = (p: PromotionProduct) =>
    p.kind === "top" && maxTopPerDay > 0
      ? Math.round((1 - perDay(p) / maxTopPerDay) * 100)
      : 0;
  const [selected, setSelected] = useState<string>(
    bestCode || products[0]?.code || "",
  );
  const [state, action, pending] = useActionState<JobFormState, FormData>(
    promoteJob,
    {},
  );

  const active = products.find((p) => p.code === selected) ?? products[0];
  const affordable = active ? balanceUzs >= active.priceUzs : false;
  const activePriceLabel = `${groupNumber(active?.priceUzs ?? 0)} so'm`;

  return (
    <form action={action} className="space-y-5">
      <input type="hidden" name="locale" value={locale} />
      <input type="hidden" name="jobId" value={jobId} />
      <input type="hidden" name="productCode" value={selected} />

      <ul className="grid gap-3 sm:grid-cols-2">
        {products.map((p, i) => {
          const isSel = p.code === selected;
          const isBest = p.code === bestCode;
          const Icon = p.kind === "featured" ? Sparkles : TrendingUp;
          return (
            <li
              key={p.code}
              className="rise-in"
              style={{ animationDelay: `${i * 70}ms` }}
            >
              <button
                type="button"
                onClick={() => setSelected(p.code)}
                aria-pressed={isSel}
                className={cn(
                  "relative flex w-full flex-col gap-1 overflow-hidden rounded-2xl border p-4 text-left transition-all duration-200",
                  isSel
                    ? "border-primary ring-primary/30 bg-accent scale-[1.02] shadow-lg ring-2"
                    : "border-border bg-card hover:border-primary/50 hover:shadow-md",
                )}
              >
                {isBest ? (
                  <span className="bg-primary text-primary-foreground absolute top-0 right-0 overflow-hidden rounded-bl-xl px-2.5 py-0.5 text-[11px] font-bold tracking-wide uppercase">
                    {t("bestValue")}
                    <span
                      className="shimmer-ribbon pointer-events-none absolute inset-0"
                      aria-hidden
                    />
                  </span>
                ) : null}
                <span className="flex items-center gap-2">
                  <Icon className="text-primary size-4 shrink-0" />
                  <span className="text-foreground font-semibold">
                    {p.name}
                  </span>
                  {isSel ? (
                    <Check className="text-primary ml-auto size-5 shrink-0" />
                  ) : null}
                </span>
                {p.description ? (
                  <span className="text-muted-foreground text-sm">
                    {p.description}
                  </span>
                ) : null}
                <span className="text-foreground mt-1 font-mono text-2xl font-bold tabular-nums">
                  {groupNumber(p.priceUzs)}
                  <span className="text-muted-foreground ml-1 text-sm font-semibold">
                    so&apos;m
                  </span>
                </span>
                <span className="text-muted-foreground flex items-center justify-between text-xs">
                  <span className="flex items-center gap-1.5">
                    {t("duration", { days: p.durationDays })}
                    {savingsOf(p) > 0 ? (
                      <span className="rounded bg-emerald-100 px-1.5 py-0.5 font-semibold text-emerald-700 dark:bg-emerald-950 dark:text-emerald-300">
                        {t("cheaper", { pct: savingsOf(p) })}
                      </span>
                    ) : null}
                  </span>
                  <span className="font-medium">
                    {t("perDay", { price: groupNumber(Math.round(perDay(p))) })}
                  </span>
                </span>
              </button>
            </li>
          );
        })}
      </ul>

      {/* Concrete payoff: your vacancy jumps to the top with a TOP badge. */}
      <div className="border-border bg-muted/40 rounded-2xl border border-dashed p-4">
        <p className="text-muted-foreground mb-2 text-xs font-medium tracking-wide uppercase">
          {t("previewLabel")}
        </p>
        <div className="space-y-2">
          <div className="border-primary bg-card flex items-center gap-2 rounded-xl border-2 p-3 shadow-sm">
            <ArrowUp className="text-primary size-4 shrink-0" />
            <span className="text-foreground truncate text-sm font-semibold">
              {jobTitle}
            </span>
            <span className="bg-primary text-primary-foreground ml-auto shrink-0 rounded-full px-2 py-0.5 text-[11px] font-bold">
              TOP
            </span>
          </div>
          <div className="border-border bg-card/50 flex items-center gap-2 rounded-xl border p-3 opacity-55">
            <span className="text-muted-foreground truncate text-sm">
              {t("previewOther")}
            </span>
          </div>
        </div>
      </div>

      <div className="border-border bg-card flex items-center justify-between rounded-xl border px-4 py-3 text-sm">
        <span className="text-muted-foreground">{t("balance")}</span>
        <span
          className={cn(
            "font-mono font-semibold tabular-nums",
            affordable ? "text-foreground" : "text-muted-foreground",
          )}
        >
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
          className={cn(
            buttonVariants({ variant: "primary", size: "lg" }),
            "cta-pulse w-full text-base",
          )}
        >
          {pending ? t("buying") : t("buyFor", { price: activePriceLabel })}
        </button>
      ) : (
        <Link
          href={`/employer/wallet?amount=${active?.priceUzs ?? ""}`}
          className={cn(
            buttonVariants({ variant: "primary", size: "lg" }),
            "w-full text-base",
          )}
        >
          {t("topUpFor", { price: activePriceLabel })}
        </Link>
      )}
    </form>
  );
}
