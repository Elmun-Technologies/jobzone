"use client";

import {
  BarChart3,
  Bell,
  Building2,
  FileText,
  Flag,
  LayoutGrid,
  Megaphone,
  Package,
  ScrollText,
  Send,
  Settings,
  Star,
  Users,
  Wallet,
  type LucideIcon,
} from "lucide-react";

import type { AdminNavGroup } from "@/lib/admin/nav";
import { adminStrings } from "@/lib/admin/strings";
import { Link, usePathname } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

const ICONS: Record<string, LucideIcon> = {
  dashboard: BarChart3,
  users: Users,
  companies: Building2,
  jobs: FileText,
  reviews: Star,
  reports: Flag,
  categories: LayoutGrid,
  telegram: Send,
  products: Package,
  blog: ScrollText,
  wallet: Wallet,
  orders: Package,
  broadcast: Megaphone,
  settings: Settings,
  audit: Bell,
};

/**
 * Admin sidebar navigation (client — needs the active pathname). Always ink,
 * volt accent on the active item, regardless of the site theme.
 */
export function SidebarNav({ groups }: { groups: AdminNavGroup[] }) {
  const pathname = usePathname();

  return (
    <nav className="flex flex-col gap-5">
      {groups.map((group) => (
        <div key={group.label}>
          <p className="px-3 text-[11px] font-semibold tracking-widest text-[#8a8a84] uppercase">
            {group.label}
          </p>
          <ul className="mt-1.5 space-y-0.5">
            {group.items.map((item) => {
              const Icon = ICONS[item.key] ?? FileText;
              const active =
                item.href === "/admin"
                  ? pathname === "/admin"
                  : pathname.startsWith(item.href);
              if (!item.enabled) {
                return (
                  <li key={item.key}>
                    <span
                      className="flex cursor-not-allowed items-center gap-2.5 rounded-lg px-3 py-2 text-sm text-[#5c5c57]"
                      title={adminStrings.comingSoon}
                    >
                      <Icon className="size-4 shrink-0" aria-hidden />
                      {item.label}
                    </span>
                  </li>
                );
              }
              return (
                <li key={item.key}>
                  <Link
                    href={item.href}
                    className={cn(
                      "flex items-center gap-2.5 rounded-lg px-3 py-2 text-sm font-medium transition-colors",
                      active
                        ? "bg-[#c7fb00] text-[#0a0a0a]"
                        : "text-[#d4d4cf] hover:bg-[#1f1f1d] hover:text-[#f3f3f1]",
                    )}
                  >
                    <Icon className="size-4 shrink-0" aria-hidden />
                    {item.label}
                  </Link>
                </li>
              );
            })}
          </ul>
        </div>
      ))}
    </nav>
  );
}
