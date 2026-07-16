import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { ForgotPasswordForm } from "@/components/auth/forgot-password-form";
import { Container } from "@/components/ui/container";
import { Link } from "@/i18n/navigation";

// Auth-adjacent form; noindex per the sign-in / sign-up policy.
export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "auth" });
  return { title: t("forgotTitle"), robots: { index: false } };
}

export default async function ForgotPasswordPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("auth");

  return (
    <Container className="flex max-w-md flex-col py-16">
      <h1 className="text-foreground mb-1 text-2xl font-bold">
        {t("forgotTitle")}
      </h1>
      <p className="text-muted-foreground mb-6 text-sm">
        {t("forgotSubtitle")}
      </p>
      <ForgotPasswordForm />
      <p className="text-muted-foreground mt-6 text-center text-sm">
        <Link
          href="/sign-in"
          className="text-primary font-semibold hover:underline"
        >
          {t("backToSignIn")}
        </Link>
      </p>
    </Container>
  );
}
