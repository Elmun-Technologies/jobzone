"use client";

import { useSession } from "@/components/auth/session-provider";

/**
 * Renders its children only for a signed-in employer.
 *
 * A visibility gate, not a security one — everything behind it is either a
 * link to a page that checks properly or, as with the share creatives, a tool
 * that is merely pointless for a job seeker. Its job is to keep a
 * role-dependent block from forcing a public page to render per request.
 */
export function EmployerOnly({ children }: { children: React.ReactNode }) {
  const { isEmployer } = useSession();
  return isEmployer ? <>{children}</> : null;
}
