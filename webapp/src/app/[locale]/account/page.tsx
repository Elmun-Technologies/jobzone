import {
  Bell,
  BellRing,
  Bookmark,
  Briefcase,
  Building2,
  FileText,
  LayoutDashboard,
  MessageSquare,
  UserCog,
  Wallet,
  type LucideIcon,
} from "lucide-react";
import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
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

type Item = {
  href: string;
  label: string;
  icon: LucideIcon;
  featured?: boolean;
};

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
  const te = await getTranslations("employer");
  const tw = await getTranslations("wallet");
  const tn = await getTranslations("nav");
  const role = await getMyRole();
  const isEmployer = role === "employer";

  // One account = one role: show that role's tools, never both. Employers get
  // the hiring tools; seekers get their applications/saved. A short shared
  // tail (messages, notifications, profile) applies to either.
  const roleItems: Item[] = isEmployer
    ? [
        {
          href: "/employer",
          label: t("employerArea"),
          icon: LayoutDashboard,
          featured: true,
        },
        { href: "/employer/jobs", label: te("myJobs"), icon: Briefcase },
        {
          href: "/employer/company/edit",
          label: te("editCompany"),
          icon: Building2,
        },
        { href: "/employer/wallet", label: tw("title"), icon: Wallet },
      ]
    : [
        {
          href: "/account/applications",
          label: t("myApplications"),
          icon: FileText,
        },
        { href: "/account/bookmarks", label: t("savedJobs"), icon: Bookmark },
        {
          href: "/account/saved-searches",
          label: t("savedSearches"),
          icon: BellRing,
        },
      ];
  const sharedItems: Item[] = [
    { href: "/account/messages", label: t("messages"), icon: MessageSquare },
    { href: "/account/notifications", label: t("notifications"), icon: Bell },
    { href: "/account/profile", label: t("editProfile"), icon: UserCog },
  ];
  const items = [...roleItems, ...sharedItems];

  return (
    <Container className="max-w-4xl py-12">
      <div className="flex flex-wrap items-center gap-3">
        <h1 className="text-foreground text-2xl font-bold">{t("title")}</h1>
        <span className="border-primary/40 bg-accent text-accent-foreground rounded-full border px-3 py-1 text-xs font-semibold">
          {isEmployer ? tn("employer") : tn("seeker")}
        </span>
      </div>
      <p className="text-muted-foreground mt-2 text-sm">
        {t("signedInAs")} <span className="font-medium">{user?.email}</span>
      </p>

      <ul className="mt-8 grid grid-cols-2 gap-3 sm:grid-cols-3">
        {items.map(({ href, label, icon: Icon, featured }) => (
          <li key={href}>
            <Link
              href={href}
              className={cn(
                "flex h-full flex-col gap-3 rounded-2xl border p-5 transition-colors",
                featured
                  ? "border-primary bg-accent"
                  : "border-border bg-card hover:border-primary/40",
              )}
            >
              <span
                className={cn(
                  "flex size-10 items-center justify-center rounded-xl",
                  featured
                    ? "bg-primary text-primary-foreground"
                    : "bg-muted text-foreground",
                )}
              >
                <Icon className="size-5" />
              </span>
              <span className="text-foreground leading-snug font-semibold">
                {label}
              </span>
            </Link>
          </li>
        ))}
      </ul>

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
