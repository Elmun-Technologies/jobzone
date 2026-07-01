import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { redirect } from "next/navigation";

import { signOutAction } from "@/lib/auth/actions";
import { getCurrentUser } from "@/lib/auth/user";
import { getMyRole } from "@/lib/data/employer";
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

// Auth-gated, per-user page. Render per request — getCurrentUser()'s try/catch
// swallows the cookies() dynamic signal, so without this Next.js bakes the
// build-time redirect (no session at prerender) into static HTML and bounces
// even signed-in users to sign-in.
export const dynamic = "force-dynamic";

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
  const role = await getMyRole();

  return (
    <Container className="max-w-2xl py-12">
      <h1 className="text-foreground text-2xl font-bold">{t("title")}</h1>
      <p className="text-muted-foreground mt-2 text-sm">
        {t("signedInAs")} <span className="font-medium">{user?.email}</span>
      </p>

      <div className="mt-8 flex flex-col gap-3">
        {role === "employer" ? (
          <Link
            href="/employer"
            className="border-primary bg-accent text-accent-foreground flex items-center justify-between rounded-xl border p-4 font-medium transition-colors"
          >
            <span>{t("employerArea")}</span>
            <span aria-hidden>→</span>
          </Link>
        ) : null}
        <Link
          href="/account/applications"
          className="border-border bg-card text-foreground hover:border-primary/40 flex items-center justify-between rounded-xl border p-4 transition-colors"
        >
          <span className="font-medium">{t("myApplications")}</span>
          <span aria-hidden>→</span>
        </Link>
        <Link
          href="/account/messages"
          className="border-border bg-card text-foreground hover:border-primary/40 flex items-center justify-between rounded-xl border p-4 transition-colors"
        >
          <span className="font-medium">{t("messages")}</span>
          <span aria-hidden>→</span>
        </Link>
        <Link
          href="/account/bookmarks"
          className="border-border bg-card text-foreground hover:border-primary/40 flex items-center justify-between rounded-xl border p-4 transition-colors"
        >
          <span className="font-medium">{t("savedJobs")}</span>
          <span aria-hidden>→</span>
        </Link>
        <Link
          href="/account/saved-searches"
          className="border-border bg-card text-foreground hover:border-primary/40 flex items-center justify-between rounded-xl border p-4 transition-colors"
        >
          <span className="font-medium">{t("savedSearches")}</span>
          <span aria-hidden>→</span>
        </Link>
        <Link
          href="/account/notifications"
          className="border-border bg-card text-foreground hover:border-primary/40 flex items-center justify-between rounded-xl border p-4 transition-colors"
        >
          <span className="font-medium">{t("notifications")}</span>
          <span aria-hidden>→</span>
        </Link>
        <Link
          href="/account/profile"
          className="border-border bg-card text-foreground hover:border-primary/40 flex items-center justify-between rounded-xl border p-4 transition-colors"
        >
          <span className="font-medium">{t("editProfile")}</span>
          <span aria-hidden>→</span>
        </Link>
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
