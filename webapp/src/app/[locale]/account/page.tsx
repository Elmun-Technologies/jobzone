import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { redirect } from "next/navigation";

import { signOutAction } from "@/lib/auth/actions";
import { getCurrentUser } from "@/lib/auth/user";
import { cn } from "@/lib/utils";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "account" });
  return { title: t("title"), robots: { index: false } };
}

export default async function AccountPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);

  // Proxy already gates this route; this is the secure (DAL-style) check.
  const user = await getCurrentUser();
  if (!user) redirect(`/${locale}/sign-in`);

  const t = await getTranslations("account");

  return (
    <Container className="max-w-2xl py-12">
      <h1 className="text-foreground text-2xl font-bold">{t("title")}</h1>
      <p className="text-muted-foreground mt-2 text-sm">
        {t("signedInAs")} <span className="font-medium">{user?.email}</span>
      </p>

      <div className="border-border bg-card mt-8 rounded-xl border p-5">
        <p className="text-muted-foreground text-sm">{t("comingSoon")}</p>
      </div>

      <form action={signOutAction} className="mt-8">
        <input type="hidden" name="locale" value={locale} />
        <button
          type="submit"
          className={cn(buttonVariants({ variant: "outline", size: "md" }))}
        >
          {t("signOut")}
        </button>
      </form>
    </Container>
  );
}
