import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { ResetPasswordForm } from "@/components/auth/reset-password-form";
import { Container } from "@/components/ui/container";
import { getCurrentUser } from "@/lib/auth/user";

// Auth/session-dependent: requires the short-lived session minted by the
// recovery link. Static prerender would defeat that gate (see CLAUDE.md's
// force-dynamic note on getCurrentUser swallowing the cookies() signal).
export const dynamic = "force-dynamic";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "auth" });
  return { title: t("resetTitle"), robots: { index: false } };
}

export default async function ResetPasswordPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);

  // The recovery-link OTP already ran on /auth/callback and minted a session.
  // If a visitor lands here without one, punt them back to /forgot-password
  // — updating the password requires a signed-in user.
  const user = await getCurrentUser();
  if (!user) redirect(`/${locale}/forgot-password`);

  const t = await getTranslations("auth");
  return (
    <Container className="flex max-w-md flex-col py-16">
      <h1 className="text-foreground mb-1 text-2xl font-bold">
        {t("resetTitle")}
      </h1>
      <p className="text-muted-foreground mb-6 text-sm">{t("resetSubtitle")}</p>
      <ResetPasswordForm />
    </Container>
  );
}
