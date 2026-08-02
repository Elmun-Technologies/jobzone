"use client";

import {
  Bookmark,
  Briefcase,
  Home,
  LayoutDashboard,
  Search,
  User,
  Users,
  type LucideIcon,
} from "lucide-react";
import { useTranslations } from "next-intl";

import { Link, usePathname } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

interface Tab {
  href: string;
  labelKey: string;
  Icon: LucideIcon;
  /** Marks this tab active for the whole subtree, not just the exact path. */
  match?: string;
}

/**
 * The phone-sized bottom navigation (below `md`).
 *
 * Every local job app the market actually uses — and the Yolla mobile app
 * itself — puts its three or four destinations in a thumb-reachable bar rather
 * than behind a hamburger. The web app had only the drawer, which costs a tap
 * and a decision before a visitor can reach Jobs or their saved list; the
 * drawer stays (it holds language, theme and the secondary links), this makes
 * the primary four one tap away and shows where you are.
 *
 * Not a duplicate of `navModel`: that is the header's mode-aware link set,
 * this is the fixed destination bar, and the two are allowed to differ (a bar
 * with five items and a shifting layout is exactly what makes bottom nav feel
 * unreliable).
 */
export function MobileTabBar({
  signedIn,
  isEmployerAccount,
}: {
  signedIn: boolean;
  isEmployerAccount: boolean;
}) {
  const t = useTranslations("nav");
  const pathname = usePathname();

  // The admin panel is a desktop tool with its own chrome — no consumer bar.
  if (pathname.startsWith("/admin")) return null;

  // A signed-in employer gets the hiring bar; guests and seekers get the
  // seeker bar even while browsing /employer/jobs/new (guest-first posting),
  // because every hiring destination behind it is gated.
  const tabs: Tab[] = isEmployerAccount
    ? [
        { href: "/employer", labelKey: "dashboard", Icon: LayoutDashboard },
        {
          href: "/employer/jobs",
          labelKey: "vacancies",
          Icon: Briefcase,
          match: "/employer/jobs",
        },
        { href: "/employer/candidates", labelKey: "candidates", Icon: Users },
        { href: "/account", labelKey: "account", Icon: User },
      ]
    : [
        { href: "/", labelKey: "home", Icon: Home },
        { href: "/jobs", labelKey: "jobs", Icon: Search, match: "/jobs" },
        {
          href: "/account/bookmarks",
          labelKey: "saved",
          Icon: Bookmark,
          match: "/account/bookmarks",
        },
        {
          // Auth-last: a guest tapping "Account" gets the sign-in page, not a
          // gated redirect bounce.
          href: signedIn ? "/account" : "/sign-in",
          labelKey: "account",
          Icon: User,
        },
      ];

  return (
    <nav
      aria-label={t("tabBar")}
      // `pb-[env(safe-area-inset-bottom)]`: iOS home-indicator clearance, so
      // the labels don't sit under the gesture bar. The matching space at the
      // end of the page comes from the body padding set in the layout.
      className="border-border bg-background/95 fixed inset-x-0 bottom-0 z-40 border-t pb-[env(safe-area-inset-bottom)] backdrop-blur md:hidden"
    >
      <ul className="grid grid-cols-4">
        {tabs.map(({ href, labelKey, Icon, match }) => {
          const active = match
            ? pathname === match || pathname.startsWith(`${match}/`)
            : pathname === href;
          return (
            <li key={href}>
              <Link
                href={href}
                aria-current={active ? "page" : undefined}
                className={cn(
                  "flex h-14 flex-col items-center justify-center gap-1 text-[11px] font-medium transition-colors",
                  active
                    ? "text-primary"
                    : "text-muted-foreground hover:text-foreground",
                )}
              >
                <Icon className={cn("size-5", active && "fill-primary/15")} />
                <span className="max-w-full truncate px-1">{t(labelKey)}</span>
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
