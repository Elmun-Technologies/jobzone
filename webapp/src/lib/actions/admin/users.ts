"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { hasSupabase } from "@/lib/data/supabase-env";
import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";

function field(formData: FormData, name: string): string {
  const v = formData.get(name);
  return typeof v === "string" ? v.trim() : "";
}

function backPath(formData: FormData): string {
  const locale = field(formData, "locale") || "uz";
  return `/${locale}/admin/users`;
}

/**
 * Grants/revokes the JWT `app_metadata.role = 'admin'` claim that gates the
 * whole panel (`is_admin()` in SQL, `isAdminUser()` in TS).
 *
 * `is_admin()` reads ONLY the JWT claim — `profiles.is_admin` is nothing more
 * than a denormalized mirror for this list's UI (0054). This used to write
 * the mirror via the RPC first and then flip the real JWT claim as a
 * "best-effort" afterthought: if that second step failed (no
 * SUPABASE_SERVICE_ROLE_KEY configured, a transient Auth Admin API error —
 * anything), the failure was only console.error'd. The mirror said
 * "revoked", the admin closed the tab believing it, and the target's JWT
 * still carried `role: admin` — full panel access, silently retained,
 * invisible in the UI that was supposed to be the record of what happened.
 *
 * Fixed by making enforcement authoritative: the JWT claim is flipped FIRST,
 * and the DB mirror (+ audit row) is written only once that has actually
 * succeeded. `admin_set_profile_admin`'s own `is_admin()` check still
 * authorizes the CALLER regardless of this order — it isn't about the
 * target's JWT, so moving it after the claim update changes nothing about
 * who is allowed to call this.
 */
export async function setProfileAdmin(formData: FormData): Promise<void> {
  const backTo = backPath(formData);
  const id = field(formData, "id");
  const makeAdmin = field(formData, "isAdmin") === "1";
  if (!id) redirect(`${backTo}?notice=err`);

  if (!hasSupabase()) {
    revalidatePath(backTo);
    return;
  }

  // The Auth Admin API is the only way to set app_metadata — it cannot be
  // done from SQL — so without the service key this action cannot make any
  // real change. Fail loudly rather than silently leaving the target's
  // actual access untouched.
  const admin = createAdminClient();
  if (!admin) {
    console.error("setProfileAdmin: no service-role client configured");
    redirect(`${backTo}?notice=authkey`);
  }

  try {
    const { data: existing, error: getErr } =
      await admin.auth.admin.getUserById(id);
    if (getErr || !existing?.user) throw getErr ?? new Error("user not found");
    const nextAppMetadata: Record<string, unknown> = {
      ...existing.user.app_metadata,
    };
    if (makeAdmin) {
      nextAppMetadata.role = "admin";
    } else if (nextAppMetadata.role === "admin") {
      delete nextAppMetadata.role;
    }
    await admin.auth.admin.updateUserById(id, {
      app_metadata: nextAppMetadata,
    });
  } catch (e) {
    console.error("setProfileAdmin: auth claim update failed", e);
    redirect(`${backTo}?notice=authkey`);
  }

  // Only reached once the real JWT claim change is confirmed. Re-checks the
  // caller (not the target) is really an admin and writes the audit row.
  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_set_profile_admin", {
    p_profile: id,
    p_is_admin: makeAdmin,
  });
  if (error) {
    console.error("admin_set_profile_admin failed", error);
    redirect(`${backTo}?notice=err`);
  }

  revalidatePath(backTo);
}
