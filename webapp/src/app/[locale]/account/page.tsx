import {
  BadgeCheck,
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
import { StatCard } from "@/components/ui/stat-card";
import { signOutAction } from "@/lib/auth/actions";
import { getCurrentUser } from "@/lib/auth/user";
import { getMyApplications } from "@/lib/data/applications";
import { getBookmarkedJobIds } from "@/lib/data/bookmarks";
import { getCompanyRating } from "@/lib/data/companies";
import { getEmployerStats, getMyCompany, getMyRole } from "@/lib/data/employer";
import { getMyProfileDetails } from "@/lib/data/profile";
import { getWallet } from "@/lib/data/wallet";
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

  const ts = await getTranslations("account.snapshot");
  const company = isEmployer ? await getMyCompany() : null;
  const [stats, wallet, rating] = company
    ? await Promise.all([
        getEmployerStats(company.id),
        getWallet(company.id),
        getCompanyRating(company.id),
      ])
    : [null, null, null];
  const [profile, applications, bookmarkIds] = !isEmployer
    ? await Promise.all([
        getMyProfileDetails(),
        getMyApplications(),
        getBookmarkedJobIds(),
      ])
    : [null, null, null];
  const seekerName = profile?.fullName || ts("seekerFallback");

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

      {/* At-a-glance snapshot: the employer's company + numbers, or the
          seeker's identity + activity — role-specific, like everything else
          on this page. */}
      {isEmployer && company ? (
        <div className="border-border bg-card mt-6 rounded-2xl border p-5">
          <div className="flex items-center gap-3">
            {company.logoUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={company.logoUrl}
                alt={company.name}
                width={48}
                height={48}
                className="size-12 shrink-0 rounded-lg object-cover"
              />
            ) : (
              <div className="bg-primary text-primary-foreground flex size-12 shrink-0 items-center justify-center rounded-lg text-lg font-bold">
                {company.name.charAt(0).toUpperCase()}
              </div>
            )}
            <div className="min-w-0">
              <p className="text-foreground flex items-center gap-1 font-semibold">
                <span className="truncate">{company.name}</span>
                {company.isVerified ? (
                  <BadgeCheck className="text-primary size-4 shrink-0" />
                ) : null}
              </p>
              {rating && rating.count > 0 ? (
                <p className="text-muted-foreground text-sm">
                  ⭐ {rating.avg.toFixed(1)} ·{" "}
                  {ts("reviews", { count: rating.count })}
                </p>
              ) : null}
            </div>
          </div>
          <div className="mt-4 grid grid-cols-3 gap-3">
            <StatCard label={ts("openJobs")} value={stats?.openJobs ?? 0} />
            <StatCard
              label={ts("applicants")}
              value={stats?.totalApplicants ?? 0}
            />
            <StatCard
              label={tw("balance")}
              value={wallet?.balanceUzs ?? 0}
              href="/employer/wallet"
            />
          </div>
        </div>
      ) : null}

      {isEmployer && !company ? (
        <div className="border-border bg-card mt-6 flex flex-wrap items-center justify-between gap-3 rounded-2xl border p-5">
          <p className="text-muted-foreground text-sm">{ts("noCompanyYet")}</p>
          <Link
            href="/employer/onboarding"
            className={cn(buttonVariants({ variant: "primary", size: "sm" }))}
          >
            {ts("createCompany")}
          </Link>
        </div>
      ) : null}

      {!isEmployer ? (
        <div className="border-border bg-card mt-6 rounded-2xl border p-5">
          <div className="flex items-center gap-3">
            <div className="bg-primary text-primary-foreground flex size-12 shrink-0 items-center justify-center rounded-lg text-lg font-bold">
              {seekerName.charAt(0).toUpperCase()}
            </div>
            <div className="min-w-0">
              <p className="text-foreground truncate font-semibold">
                {seekerName}
              </p>
              {profile?.headline ? (
                <p className="text-muted-foreground truncate text-sm">
                  {profile.headline}
                </p>
              ) : null}
            </div>
          </div>
          <div className="mt-4 grid grid-cols-2 gap-3">
            <StatCard
              label={ts("applications")}
              value={applications?.length ?? 0}
            />
            <StatCard label={t("savedJobs")} value={bookmarkIds?.size ?? 0} />
          </div>
        </div>
      ) : null}

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
