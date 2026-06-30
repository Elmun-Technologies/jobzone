import "server-only";

import { createClient } from "@/lib/supabase/server";

import { hasSupabase } from "./supabase-env";

export interface ProfileDetails {
  fullName: string;
  headline: string;
  bio: string;
  phone: string;
  city: string;
  country: string;
}

const EMPTY: ProfileDetails = {
  fullName: "",
  headline: "",
  bio: "",
  phone: "",
  city: "",
  country: "",
};

const str = (v: unknown) => (typeof v === "string" ? v : "");

/** The signed-in user's own editable profile fields. */
export async function getMyProfileDetails(): Promise<ProfileDetails | null> {
  if (!hasSupabase()) return null;
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return null;
    const { data } = await supabase
      .from("profiles")
      .select("full_name, headline, bio, phone, city, country")
      .eq("id", user.id)
      .maybeSingle();
    if (!data) return EMPTY;
    const r = data as Record<string, unknown>;
    return {
      fullName: str(r.full_name),
      headline: str(r.headline),
      bio: str(r.bio),
      phone: str(r.phone),
      city: str(r.city),
      country: str(r.country),
    };
  } catch {
    return EMPTY;
  }
}
