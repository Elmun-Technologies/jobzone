import type { Metadata } from "next";
import { ArrowDownLeft, ArrowUpRight, Wallet } from "lucide-react";
import { redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { Container } from "@/components/ui/container";
import { EmptyState } from "@/components/ui/states";
import { TopUpForm } from "@/components/employer/top-up-form";
import { getMyCompany } from "@/lib/data/employer";
import { getWallet, type WalletTransaction } from "@/lib/data/wallet";
import { requireEmployer } from "@/lib/auth/require-employer";
import { formatDate, groupNumber } from "@/lib/format";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "wallet" });
  return { title: t("title"), robots: { index: false } };
}

function TxRow({
  tx,
  label,
  meta,
}: {
  tx: WalletTransaction;
  label: string;
  meta: string;
}) {
  const credit = tx.amountUzs >= 0;
  const Icon = credit ? ArrowDownLeft : ArrowUpRight;
  const pending = tx.status !== "completed";
  return (
    <li className="flex items-center gap-3 py-3">
      <span
        className={`flex size-9 shrink-0 items-center justify-center rounded-full ${
          credit
            ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-950 dark:text-emerald-300"
            : "bg-muted text-muted-foreground"
        }`}
      >
        <Icon className="size-4" />
      </span>
      <div className="min-w-0 flex-1">
        <p className="text-foreground truncate text-sm font-medium">{label}</p>
        <p className="text-muted-foreground text-xs">{meta}</p>
      </div>
      <span
        className={`shrink-0 font-mono text-sm font-semibold tabular-nums ${
          pending
            ? "text-muted-foreground"
            : credit
              ? "text-emerald-600 dark:text-emerald-400"
              : "text-foreground"
        }`}
      >
        {credit ? "+" : "−"}
        {groupNumber(Math.abs(tx.amountUzs))}
      </span>
    </li>
  );
}

// Auth-gated, per-employer page (reads the session via requireEmployer). Render
// per request — getCurrentUser()'s try/catch swallows the cookies() dynamic
// signal, so without this Next.js would prerender one shared, logged-out copy.
export const dynamic = "force-dynamic";

export default async function WalletPage({
  params,
  searchParams,
}: {
  params: Promise<{ locale: string }>;
  searchParams: Promise<{ amount?: string }>;
}) {
  const { locale } = await params;
  // ?amount rides over from the promote page's "top up" CTA so the form opens
  // pre-filled with exactly what the chosen boost needs. Digits only, bounded.
  const { amount } = await searchParams;
  const presetAmount = (amount ?? "").replace(/\D/g, "").slice(0, 12);
  setRequestLocale(locale);
  await requireEmployer(locale);

  const company = await getMyCompany();
  if (!company) redirect(`/${locale}/employer/onboarding`);

  const t = await getTranslations("wallet");
  const wallet = await getWallet(company.id);

  return (
    <Container className="max-w-2xl py-10">
      <div className="mb-6 flex items-center gap-2">
        <Wallet className="text-primary size-6" />
        <h1 className="text-foreground text-2xl font-bold">{t("title")}</h1>
      </div>

      {/* Balance */}
      <section className="border-border bg-card rounded-2xl border p-6">
        <p className="text-muted-foreground text-sm">{t("balance")}</p>
        <p className="text-foreground mt-1 font-mono text-4xl font-bold tabular-nums">
          {groupNumber(wallet.balanceUzs)}{" "}
          <span className="text-muted-foreground text-xl font-semibold">
            so&apos;m
          </span>
        </p>
        <p className="text-muted-foreground mt-2 text-sm">{t("balanceHint")}</p>
      </section>

      {/* Top up */}
      <section className="border-border bg-card mt-6 rounded-2xl border p-6">
        <h2 className="text-foreground mb-1 text-lg font-bold">{t("topUp")}</h2>
        <p className="text-muted-foreground mb-4 text-sm">{t("topUpSub")}</p>
        <TopUpForm companyId={company.id} initialAmount={presetAmount} />
      </section>

      {/* History */}
      <section className="mt-8">
        <h2 className="text-foreground mb-2 text-lg font-bold">
          {t("history")}
        </h2>
        {wallet.transactions.length === 0 ? (
          <EmptyState title={t("historyEmpty")} />
        ) : (
          <ul className="border-border divide-border bg-card divide-y rounded-2xl border px-4">
            {wallet.transactions.map((tx) => (
              <TxRow
                key={tx.id}
                tx={tx}
                label={tx.description ?? t(`kind.${tx.kind}`)}
                meta={
                  formatDate(tx.createdAt) +
                  (tx.status !== "completed"
                    ? ` · ${t(`status.${tx.status}`)}`
                    : "")
                }
              />
            ))}
          </ul>
        )}
      </section>
    </Container>
  );
}
