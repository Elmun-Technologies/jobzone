import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { redirect } from "next/navigation";

import { signOutAction } from "@/lib/auth/actions";
import { getCurrentUser } from "@/lib/auth/user";
import { Link } from "@/i18n/navigation";
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

      <div className="mt-8 flex flex-col gap-3">
        <Link
          href="/account/applications"
          className="border-border bg-card text-foreground hover:border-primary/40 flex items-center justify-between rounded-xl border p-4 transition-colors"
        >
          <span className="font-medium">{t("myApplications")}</span>
          <span aria-hidden>→</span>
        </Link>
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
