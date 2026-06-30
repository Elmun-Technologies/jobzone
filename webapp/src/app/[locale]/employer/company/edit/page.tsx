import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { CompanyForm } from "@/components/employer/company-form";
import { Container } from "@/components/ui/container";
import { updateCompany } from "@/lib/actions/employer";
import { getMyCompany } from "@/lib/data/employer";
import { requireEmployer } from "@/lib/auth/require-employer";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "employer" });
  return { title: t("editCompany"), robots: { index: false } };
}

export default async function EditCompanyPage({
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

  return (
    <Container className="max-w-xl py-12">
      <h1 className="text-foreground mb-6 text-2xl font-bold">
        {t("editCompany")}
      </h1>
      <CompanyForm
        action={updateCompany}
        submitLabel={t("saveChanges")}
        initial={{
          id: company.id,
          name: company.name,
          about: company.about,
          industry: company.industry,
          website: company.website,
          headquarters: company.headquarters,
        }}
      />
    </Container>
  );
}
