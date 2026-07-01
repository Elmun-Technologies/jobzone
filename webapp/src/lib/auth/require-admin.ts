import "server-only";

import { notFound, redirect } from "next/navigation";

import { hasSupabase } from "@/lib/data/supabase-env";

import { isAdminUser } from "./admin-role";
import { getCurrentUser } from "./user";

/**
 * Gate for the /admin subtree: requires a signed-in platform admin (JWT
 * app_metadata.role === 'admin', matching the DB `is_admin()` gate). Non-admins
 * get a 404 so the panel stays invisible. Without Supabase env the panel runs
 * in mock/demo mode, like the rest of the app. Every admin page must call this
 * (layouts don't re-run on client navigation) — and RLS + the `is_admin()`
 * check inside every admin RPC remain the real guard on mutations.
 */
export async function requireAdmin(
  locale: string,
): Promise<{ userId: string; mock: boolean }> {
  if (!hasSupabase()) return { userId: "mock-admin", mock: true };
  const user = await getCurrentUser();
  if (!user) redirect(`/${locale}/sign-in?next=/${locale}/admin`);
  if (!isAdminUser(user)) notFound();
  return { userId: user.id, mock: false };
}
