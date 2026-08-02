"use server";

import { redirect } from "next/navigation";

import { routing, type Locale } from "@/i18n/routing";
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

/**
 * Mirrors the reader's chosen language into `profiles.preferred_locale`.
 *
 * The URL prefix and the next-intl cookie only tell *this browser*. Everything
 * the backend sends outward — Telegram messages, FCM push — is composed
 * server-side, where neither is visible, so without this the column keeps its
 * 0001 default of 'en' for every account and those messages go out in a
 * language most recipients do not read.
 *
 * Best-effort by design: a guest has no row to write, and switching language
 * must never fail or block on it.
 */
export async function setPreferredLocale(locale: string): Promise<void> {
  if (!routing.locales.includes(locale as Locale)) return;
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return;
    await supabase
      .from("profiles")
      .update({ preferred_locale: locale })
      .eq("id", user.id);
  } catch (e) {
    console.error("setPreferredLocale failed", e);
  }
}
