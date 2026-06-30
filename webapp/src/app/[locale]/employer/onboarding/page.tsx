import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { CreateCompanyForm } from "@/components/employer/create-company-form";
import { Container } from "@/components/ui/container";
import { getMyCompany } from "@/lib/data/employer";
import { requireEmployer } from "@/lib/auth/require-employer";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "employer" });
  return { title: t("onboardingTitle"), robots: { index: false } };
}

export default async function EmployerOnboardingPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  await requireEmployer(locale);

  const company = await getMyCompany();
  if (company) redirect(`/${locale}/employer`);

  const t = await getTranslations("employer");

  return (
    <Container className="max-w-xl py-12">
      <h1 className="text-foreground mb-1 text-2xl font-bold">
        {t("onboardingTitle")}
      </h1>
      <p className="text-muted-foreground mb-6 text-sm">
        {t("onboardingSubtitle")}
      </p>
      <CreateCompanyForm />
    </Container>
  );
}
