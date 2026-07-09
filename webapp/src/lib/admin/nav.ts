import { adminStrings } from "./strings";

const n = adminStrings.nav;

export interface AdminNavItem {
  /** Stable key — the client sidebar maps it to a lucide icon. */
  key: string;
  label: string;
  /** Locale-relative path ("/admin/users"). */
  href: string;
  /** Sections land PR by PR; disabled ones render as "Tez kunda". */
  enabled: boolean;
}

export interface AdminNavGroup {
  label: string;
  items: AdminNavItem[];
}

/** The panel's information architecture. Flip `enabled` as sections ship. */
export const adminNav: AdminNavGroup[] = [
  {
    label: n.groups.overview,
    items: [
      { key: "dashboard", label: n.dashboard, href: "/admin", enabled: true },
    ],
  },
  {
    label: n.groups.moderation,
    items: [
      { key: "users", label: n.users, href: "/admin/users", enabled: true },
      { key: "companies", label: n.companies, href: "/admin/companies", enabled: true },
      { key: "jobs", label: n.jobs, href: "/admin/jobs", enabled: true },
      { key: "reviews", label: n.reviews, href: "/admin/reviews", enabled: true },
    ],
  },
  {
    label: n.groups.content,
    items: [
      { key: "categories", label: n.categories, href: "/admin/categories", enabled: true },
      { key: "products", label: n.products, href: "/admin/products", enabled: false },
      { key: "blog", label: n.blog, href: "/admin/blog", enabled: false },
    ],
  },
  {
    label: n.groups.finance,
    items: [
      { key: "wallet", label: n.wallet, href: "/admin/finance", enabled: true },
      { key: "orders", label: n.orders, href: "/admin/orders", enabled: true },
    ],
  },
  {
    label: n.groups.system,
    items: [
      { key: "broadcast", label: n.broadcast, href: "/admin/broadcast", enabled: true },
      { key: "settings", label: n.settings, href: "/admin/settings", enabled: false },
      { key: "audit", label: n.audit, href: "/admin/audit", enabled: true },
    ],
  },
];
