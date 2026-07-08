import type { Metadata } from "next";
import { Megaphone } from "lucide-react";
import { notFound, redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { PromotePicker } from "@/components/employer/promote-picker";
import { Container } from "@/components/ui/container";
import { EmptyState } from "@/components/ui/states";
import { buttonVariants } from "@/components/ui/button";
import { getEmployerJobBoost, getMyCompany } from "@/lib/data/employer";
import { getPromotionProducts } from "@/lib/data/pricing";
import { getWallet } from "@/lib/data/wallet";
import { requireEmployer } from "@/lib/auth/require-employer";
import { formatDate } from "@/lib/format";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "promote" });
  return { title: t("title"), robots: { index: false } };
}

// Auth-gated, per-employer. Render per request (see the wallet/dashboard note).
export const dynamic = "force-dynamic";

export default async function PromoteJobPage({
  params,
}: {
  params: Promise<{ locale: string; id: string }>;
}) {
  const { locale, id } = await params;
  setRequestLocale(locale);
  await requireEmployer(locale);

  const company = await getMyCompany();
  if (!company) redirect(`/${locale}/employer/onboarding`);

  const [t, job, products, wallet] = await Promise.all([
    getTranslations("promote"),
    getEmployerJobBoost(id),
    getPromotionProducts(),
    getWallet(company.id),
  ]);
  // getEmployerJobBoost already confirmed ownership; null → not theirs / gone.
  if (!job) notFound();

  return (
    <Container className="max-w-2xl py-10">
      <div className="mb-2 flex items-center gap-2">
        <Megaphone className="text-primary size-6" />
        <h1 className="text-foreground text-2xl font-bold">{t("title")}</h1>
      </div>
      <p className="text-muted-foreground text-sm">{t("subtitle")}</p>
      <p className="text-foreground mt-1 mb-6 font-medium">
        {t("forJob", { title: job.title })}
      </p>

      {job.status !== "open" ? (
        <>
          <EmptyState
            title={t("notOpenTitle")}
            description={t("notOpenHint")}
          />
          <div className="mt-4 flex justify-center">
            <Link
              href="/employer/jobs"
              className={cn(buttonVariants({ variant: "outline", size: "sm" }))}
            >
              {t("back")}
            </Link>
          </div>
        </>
      ) : (
        <>
          {job.boostActive ? (
            <div className="border-primary/40 bg-accent text-accent-foreground mb-6 rounded-xl border px-4 py-3 text-sm font-medium">
              {t("activeUntil", { date: formatDate(job.boostedUntil) })}
            </div>
          ) : null}

          <PromotePicker
            jobId={job.id}
            locale={locale}
            products={products}
            balanceUzs={wallet.balanceUzs}
          />
        </>
      )}
    </Container>
  );
}
