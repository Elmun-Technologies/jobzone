import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { CompanyForm } from "@/components/employer/company-form";
import { Container } from "@/components/ui/container";
import { createCompany } from "@/lib/actions/employer";
import { getMyCompany } from "@/lib/data/employer";
import { getCurrentUser } from "@/lib/auth/user";

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
  searchParams,
}: {
  params: Promise<{ locale: string }>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  const sp = await searchParams;
  const next = typeof sp.next === "string" ? sp.next : undefined;

  // Auth-only gate (no role check): creating a company is how a signed-in
  // seeker *becomes* an employer — createCompany flips profiles.role to match.
  const user = await getCurrentUser();
  if (!user) {
    redirect(`/${locale}/sign-in?next=/${locale}/employer/onboarding`);
  }

  const company = await getMyCompany();
  if (company) redirect(next || `/${locale}/employer`);

  const t = await getTranslations("employer");

  return (
    <Container className="max-w-xl py-12">
      <h1 className="text-foreground mb-1 text-2xl font-bold">
        {t("onboardingTitle")}
      </h1>
      <p className="text-muted-foreground mb-6 text-sm">
        {t("onboardingSubtitle")}
      </p>
      <CompanyForm
        action={createCompany}
        submitLabel={t("createCompany")}
        next={next}
      />
    </Container>
  );
}
