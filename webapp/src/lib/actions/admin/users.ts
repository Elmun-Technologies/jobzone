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
 * whole panel (`is_admin()` in SQL, `isAdminUser()` in TS). The RPC
 * (`admin_set_profile_admin`, 0054) runs first on the caller's own session
 * client — it re-checks the caller is really an admin and is what authorizes
 * this whole action, exactly like every other moderation action in
 * `actions/admin/moderation.ts`. Only once that succeeds do we reach for the
 * service-role Auth Admin API to actually flip the target's JWT claim (the
 * only way to set it — it can't be done from SQL). Revocation takes effect
 * for the affected user on their next token refresh — inherent to any
 * JWT-claim scheme, not specific to this action.
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

  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_set_profile_admin", {
    p_profile: id,
    p_is_admin: makeAdmin,
  });
  if (error) {
    console.error("admin_set_profile_admin failed", error);
    redirect(`${backTo}?notice=err`);
  }

  // Best-effort: actually flip the JWT claim. If this fails the DB mirror
  // still reflects intent (visible in the list + audit log), same tradeoff
  // `setProfileSuspended` already makes for the auth-level ban call.
  const admin = createAdminClient();
  if (admin) {
    try {
      const { data: existing, error: getErr } = await admin.auth.admin.getUserById(id);
      if (getErr || !existing?.user) throw getErr ?? new Error("user not found");
      const nextAppMetadata: Record<string, unknown> = {
        ...existing.user.app_metadata,
      };
      if (makeAdmin) {
        nextAppMetadata.role = "admin";
      } else if (nextAppMetadata.role === "admin") {
        delete nextAppMetadata.role;
      }
      await admin.auth.admin.updateUserById(id, { app_metadata: nextAppMetadata });
    } catch (e) {
      console.error("setProfileAdmin: auth claim update failed", e);
    }
  }

  revalidatePath(backTo);
}
