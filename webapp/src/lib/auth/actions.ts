"use server";

import { redirect } from "next/navigation";

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

  const next = field(formData, "next");
  redirect(next || localePath(formData, "/account"));
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

  const supabase = await createClient();
  const { error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { role } },
  });
  if (error)
    return { error: error.message.includes("already") ? "inUse" : "unknown" };

  // With email confirmations disabled the user is signed in immediately.
  redirect(localePath(formData, "/account"));
}

/** Sign out and return to the welcome/landing page. */
export async function signOutAction(formData: FormData): Promise<void> {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect(localePath(formData, "/"));
}
