import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { DeleteAccountForm } from "@/components/account/delete-account-form";
import { Container } from "@/components/ui/container";
import { getCurrentUser } from "@/lib/auth/user";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "settings" });
  return { title: t("title"), robots: { index: false } };
}

// getCurrentUser wraps cookies() in try/catch which swallows the dynamic
// signal; without force-dynamic Next static-prerenders the redirect
// branch and every visitor bounces to sign-in.
export const dynamic = "force-dynamic";

export default async function SettingsPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  const user = await getCurrentUser();
  if (!user) redirect(`/${locale}/sign-in`);

  const t = await getTranslations("settings");
  return (
    <Container className="max-w-2xl py-10">
      <h1 className="text-foreground text-2xl font-bold">{t("title")}</h1>
      <p className="text-muted-foreground mt-1 text-sm">{t("subtitle")}</p>

      <section className="border-destructive/40 mt-8 rounded-2xl border p-5">
        <h2 className="text-destructive text-lg font-semibold">
          {t("dangerZone")}
        </h2>
        <p className="text-muted-foreground mt-2 text-sm leading-relaxed">
          {t("deleteWarning")}
        </p>
        <div className="mt-4">
          <DeleteAccountForm locale={locale} />
        </div>
      </section>
    </Container>
  );
}
