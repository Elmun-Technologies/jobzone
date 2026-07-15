"use server";

import { headers } from "next/headers";
import { redirect } from "next/navigation";

import { safeNext } from "@/lib/auth/safe-next";
import { createClient } from "@/lib/supabase/server";

export interface AuthFormState {
  error?: string;
}

function field(formData: FormData, name: string): string {
  return (formData.get(name) ?? "").toString().trim();
}

function localePath(formData: FormData, path: string): string {
  const locale = field(formData, "locale") || "uz";
  return `/${locale}${path}`;
}

/** Email/password sign-in. On success redirects to `next` (or /account). */
export async function signInAction(
  _prev: AuthFormState,
  formData: FormData,
): Promise<AuthFormState> {
  const email = field(formData, "email");
  const password = field(formData, "password");
  if (!email || !password) return { error: "missing" };

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) return { error: "invalid" };

  redirect(safeNext(field(formData, "next"), localePath(formData, "/account")));
}

/** Email/password sign-up with a chosen role (job_seeker | employer). */
export async function signUpAction(
  _prev: AuthFormState,
  formData: FormData,
): Promise<AuthFormState> {
  const email = field(formData, "email");
  const password = field(formData, "password");
  const role = field(formData, "role") || "job_seeker";
  if (!email || password.length < 6) return { error: "weak" };

  const next = safeNext(
    field(formData, "next"),
    localePath(formData, "/account"),
  );

  // If "Confirm email" is ON in Supabase, the confirmation link must land on
  // /auth/callback (which exchanges the code for a session) — without an
  // explicit emailRedirectTo it falls back to the bare Site URL, where the
  // code is silently dropped and the user stays signed out.
  const h = await headers();
  const origin = `${h.get("x-forwarded-proto") ?? "https"}://${h.get("host") ?? ""}`;

  const supabase = await createClient();
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: { role },
      emailRedirectTo: `${origin}/auth/callback?next=${encodeURIComponent(next)}`,
    },
  });
  if (error)
    return { error: error.message.includes("already") ? "inUse" : "unknown" };

  // Confirmations disabled → signed in immediately, go where the user was headed.
  if (data.session) redirect(next);

  // Confirmations enabled → no session yet. Explain the pending email on the
  // sign-in page instead of bouncing through the auth gate (which reads as
  // "sign-up silently failed").
  const query = new URLSearchParams({ notice: "confirm", next });
  redirect(`${localePath(formData, "/sign-in")}?${query.toString()}`);
}

/** Sign out and return to the welcome/landing page. */
export async function signOutAction(formData: FormData): Promise<void> {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect(localePath(formData, "/"));
}
