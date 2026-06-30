"use server";

import { redirect } from "next/navigation";

import { createClient } from "@/lib/supabase/server";

export interface ProfileFormState {
  error?: string;
}

function field(formData: FormData, name: string): string {
  return (formData.get(name) ?? "").toString().trim();
}
function optional(formData: FormData, name: string): string | null {
  return field(formData, name) || null;
}

/** Updates the signed-in user's own profile (RLS: update own). */
export async function updateProfile(
  _prev: ProfileFormState,
  formData: FormData,
): Promise<ProfileFormState> {
  const locale = field(formData, "locale") || "uz";
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect(`/${locale}/sign-in`);

  const { error } = await supabase
    .from("profiles")
    .update({
      full_name: optional(formData, "fullName"),
      headline: optional(formData, "headline"),
      bio: optional(formData, "bio"),
      phone: optional(formData, "phone"),
      city: optional(formData, "city"),
      country: optional(formData, "country"),
    })
    .eq("id", user.id);
  if (error) return { error: "unknown" };

  redirect(`/${locale}/account`);
}
