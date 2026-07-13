import type { Metadata } from "next";
import { notFound, redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { PostJobForm } from "@/components/employer/post-job-form";
import { Container } from "@/components/ui/container";
import { getCategories } from "@/lib/data/categories";
import {
  getEmployerJobDraft,
  getEmployerStats,
  getMyCompany,
} from "@/lib/data/employer";
import { requireEmployer } from "@/lib/auth/require-employer";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "employer" });
  return { title: t("editJob"), robots: { index: false } };
}

// Auth-gated, per-employer. Render per request (see the wallet/dashboard note).
export const dynamic = "force-dynamic";

export default async function EditJobPage({
  params,
}: {
  params: Promise<{ locale: string; id: string }>;
}) {
  const { locale, id } = await params;
  setRequestLocale(locale);
  await requireEmployer(locale);

  const company = await getMyCompany();
  if (!company) redirect(`/${locale}/employer/onboarding`);

  const [t, categories, draft, stats] = await Promise.all([
    getTranslations("employer"),
    getCategories(),
    getEmployerJobDraft(id),
    getEmployerStats(company.id),
  ]);
  // getEmployerJobDraft already confirmed ownership; null → not theirs / gone.
  if (!draft) notFound();

  return (
    <Container className="py-10">
      <h1 className="text-foreground mb-6 text-2xl font-bold">
        {t("editJob")}
      </h1>
      <PostJobForm
        companyId={company.id}
        companyName={company.name}
        categories={categories}
        hasPublishedBefore={stats.hasPublishedBefore}
        editJob={{ id, draft }}
      />
    </Container>
  );
}
