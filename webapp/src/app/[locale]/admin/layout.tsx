import type { Metadata } from "next";
import { setRequestLocale } from "next-intl/server";

import { AdminShell } from "@/components/admin/admin-shell";
import { adminStrings } from "@/lib/admin/strings";
import { requireAdmin } from "@/lib/auth/require-admin";

// noindex for the whole /admin subtree (robots.ts additionally disallows it).
export const metadata: Metadata = {
  title: adminStrings.panelTitle,
  robots: { index: false },
};

export default async function AdminLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  // Defense-in-depth only: layouts don't re-run on client navigation in this
  // Next version, so every admin PAGE calls requireAdmin() itself as well.
  await requireAdmin(locale);

  return <AdminShell>{children}</AdminShell>;
}
