import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { PostJobForm } from "@/components/employer/post-job-form";
import { Container } from "@/components/ui/container";
import { getCategories } from "@/lib/data/categories";
import { getMyCompany } from "@/lib/data/employer";
import { requireEmployer } from "@/lib/auth/require-employer";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "employer" });
  return { title: t("postJob"), robots: { index: false } };
}

export default async function PostJobPage({
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
  const categories = await getCategories();

  return (
    <Container className="py-10">
      <h1 className="text-foreground mb-6 text-2xl font-bold">
        {t("postJob")}
      </h1>
      <PostJobForm companyId={company.id} categories={categories} />
    </Container>
  );
}
