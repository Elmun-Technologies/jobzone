import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { getEmployerStats, getMyCompany } from "@/lib/data/employer";
import { requireEmployer } from "@/lib/auth/require-employer";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "employer" });
  return { title: t("dashboard"), robots: { index: false } };
}

function Stat({ label, value }: { label: string; value: number }) {
  return (
    <div className="border-border bg-card rounded-xl border p-5">
      <p className="text-foreground text-3xl font-bold">{value}</p>
      <p className="text-muted-foreground mt-1 text-sm">{label}</p>
    </div>
  );
}

export default async function EmployerDashboardPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  await requireEmployer(locale);

  const company = await getMyCompany();
  if (!company) redirect(`/${locale}/employer/onboarding`);

  const t = await getTranslations("employer");
  const stats = await getEmployerStats(company.id);

  return (
    <Container className="py-10">
      <p className="text-muted-foreground text-sm">{t("dashboard")}</p>
      <h1 className="text-foreground text-2xl font-bold">{company.name}</h1>

      <div className="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-3">
        <Stat label={t("statOpenJobs")} value={stats.openJobs} />
        <Stat label={t("statApplicants")} value={stats.totalApplicants} />
        <Stat label={t("statJobs")} value={stats.totalJobs} />
      </div>

      <div className="mt-8 flex flex-wrap gap-3">
        <Link
          href="/employer/jobs/new"
          className={cn(buttonVariants({ variant: "primary", size: "md" }))}
        >
          {t("postJob")}
        </Link>
        <Link
          href="/employer/jobs"
          className={cn(buttonVariants({ variant: "outline", size: "md" }))}
        >
          {t("myJobs")}
        </Link>
      </div>
    </Container>
  );
}
