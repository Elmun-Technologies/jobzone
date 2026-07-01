"use server";

import { revalidatePath } from "next/cache";

import { createClient } from "@/lib/supabase/server";

export interface SaveSearchResult {
  ok?: boolean;
  signedOut?: boolean;
  error?: boolean;
}

/**
 * Saves the current search criteria for the signed-in seeker. Guest-first: if
 * the visitor isn't authenticated it returns `signedOut` (the caller sends them
 * to sign in and back — the search itself lives in the URL, so nothing is
 * lost). RLS confines the row to the owner via profile_id = auth.uid().
 */
export async function saveSearch(input: {
  locale: string;
  name: string;
  keywords?: string;
  city?: string;
}): Promise<SaveSearchResult> {
  const name = input.name.trim();
  if (!name) return { error: true };

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { signedOut: true };

  const { error } = await supabase.from("saved_searches").insert({
    profile_id: user.id,
    name,
    keywords: input.keywords?.trim() || null,
    city: input.city?.trim() || null,
  });
  if (error) return { error: true };

  revalidatePath(`/${input.locale}/account/saved-searches`);
  return { ok: true };
}

/** Removes a saved search (RLS restricts the delete to the owner's rows). */
export async function deleteSavedSearch(
  id: string,
  locale: string,
): Promise<void> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return;
  await supabase.from("saved_searches").delete().eq("id", id);
  revalidatePath(`/${locale}/account/saved-searches`);
}
