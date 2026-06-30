import "server-only";

import { redirect } from "next/navigation";

import { getMyRole } from "@/lib/data/employer";

import { getCurrentUser } from "./user";

/**
 * Gate for the /employer subtree: requires an authenticated employer. Redirects
 * unauthenticated users to sign-in and non-employers to their seeker account.
 * (RLS is the real guard on mutations; this is the UX/optimistic check.)
 */
export async function requireEmployer(
  locale: string,
): Promise<{ userId: string }> {
  const user = await getCurrentUser();
  if (!user) redirect(`/${locale}/sign-in?next=/${locale}/employer`);
  const role = await getMyRole();
  if (role !== "employer") redirect(`/${locale}/account`);
  return { userId: user.id };
}
