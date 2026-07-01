import type { User } from "@supabase/supabase-js";

/**
 * Mirrors the DB `is_admin()` gate (0016_verification.sql): a platform admin
 * is a user whose JWT carries app_metadata.role === 'admin'. app_metadata is
 * server-only (set via the Supabase dashboard / Admin API — never by the
 * client), so this check agrees with RLS exactly. Note: NOT `profiles.role`,
 * which only holds job_seeker/employer.
 */
export function isAdminUser(user: User | null | undefined): boolean {
  const meta = user?.app_metadata as { role?: string } | undefined;
  return meta?.role === "admin";
}
