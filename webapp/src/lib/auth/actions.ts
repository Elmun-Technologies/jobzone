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
  // ToS acceptance — the sign-up form has `required` on the checkbox, but a
  // scripted POST could omit it. Reject server-side so the click-to-accept
  // audit line "you must have checked the box to reach this branch" holds.
  const tosAccepted = field(formData, "tos") === "on";
  if (!tosAccepted) return { error: "tos" };
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
  const nextMarked = withSignupMark(next);
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: { role },
      // Sends `signup=1` on the destination so the client-side funnel event
      // fires on the first authenticated page load after email confirmation.
      emailRedirectTo: `${origin}/auth/callback?next=${encodeURIComponent(nextMarked)}`,
    },
  });
  if (error)
    return { error: error.message.includes("already") ? "inUse" : "unknown" };

  // Confirmations disabled → signed in immediately, go where the user was
  // headed. The `signup=1` mark on the destination is what lets the client
  // fire the signup_complete funnel event exactly once.
  if (data.session) redirect(nextMarked);

  // Confirmations enabled → no session yet. Explain the pending email on the
  // sign-in page instead of bouncing through the auth gate (which reads as
  // "sign-up silently failed").
  const query = new URLSearchParams({ notice: "confirm", next: nextMarked });
  redirect(`${localePath(formData, "/sign-in")}?${query.toString()}`);
}

/**
 * Append `signup=1` to a same-origin path safely — used to mark the first
 * page a fresh signup lands on so the client-side PageEvent can fire the
 * funnel event. Preserves any pre-existing query without duplicating the
 * mark. Absolute URLs are refused (safeNext already forbids them).
 */
function withSignupMark(path: string): string {
  const [pathname, search = ""] = path.split("?");
  const params = new URLSearchParams(search);
  params.set("signup", "1");
  return `${pathname}?${params.toString()}`;
}

/** Sign out and return to the welcome/landing page. */
export async function signOutAction(formData: FormData): Promise<void> {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect(localePath(formData, "/"));
}

export interface PasswordResetFormState extends AuthFormState {
  sent?: boolean;
}

/**
 * Start the password-recovery flow. Sends a magic-link email that lands on
 * `/auth/callback?type=recovery&next=/{locale}/reset-password`; the callback
 * mints a short-lived session and forwards to the reset form, where
 * `updatePasswordAction` finalises the new password.
 *
 * The response is *intentionally opaque*: whether or not the address is
 * registered, the user sees "we sent you a link" — otherwise the form is an
 * account-enumeration oracle.
 */
export async function sendPasswordResetAction(
  _prev: PasswordResetFormState,
  formData: FormData,
): Promise<PasswordResetFormState> {
  const email = field(formData, "email");
  if (!email) return { error: "missing" };

  const h = await headers();
  const origin = `${h.get("x-forwarded-proto") ?? "https"}://${h.get("host") ?? ""}`;
  const localeReset = localePath(formData, "/reset-password");
  const redirectTo = `${origin}/auth/callback?next=${encodeURIComponent(localeReset)}`;

  const supabase = await createClient();
  await supabase.auth.resetPasswordForEmail(email, { redirectTo });
  // Ignore the underlying result: "user not found" and "sent successfully"
  // both surface as "sent" to the user.
  return { sent: true };
}

/**
 * Finalises the recovery flow. Requires the session minted by the recovery
 * link on `/auth/callback` — `updateUser({password})` uses the current
 * user's uid, and the middleware carries that session cookie into this
 * action.
 */
export async function updatePasswordAction(
  _prev: AuthFormState,
  formData: FormData,
): Promise<AuthFormState> {
  const password = field(formData, "password");
  const confirm = field(formData, "confirm");
  if (password.length < 6) return { error: "weak" };
  if (password !== confirm) return { error: "mismatch" };

  const supabase = await createClient();
  const { error } = await supabase.auth.updateUser({ password });
  if (error) return { error: "unknown" };

  // Session was refreshed with the new password; forward straight into
  // the account. `next` isn't honored here — recovery links open in a fresh
  // browser context and shouldn't inherit stale intent.
  redirect(localePath(formData, "/account"));
}

export interface DeleteAccountFormState extends AuthFormState {
  ok?: boolean;
}

/**
 * Self-service account deletion (Apple 5.1.1(v), Play Data Safety). The
 * form gates with a typed confirmation phrase; if that passes we forward
 * the caller's JWT to the `delete-account` edge function, which uses the
 * service-role client to remove the auth.users row. Every user-scoped
 * table cascades from profiles.id (0001), so no other cleanup is needed.
 *
 * On success we sign out (server-side supabase already lost the user) and
 * redirect to /. If the edge fn fails we surface an opaque `error` so the
 * user can retry.
 */
export async function deleteAccountAction(
  _prev: DeleteAccountFormState,
  formData: FormData,
): Promise<DeleteAccountFormState> {
  const confirm = field(formData, "confirm");
  // The form asks the user to type DELETE (or a locale equivalent). Server
  // enforces the check so a scripted POST can't skip it.
  if (confirm.toUpperCase() !== "DELETE") return { error: "confirm" };

  const supabase = await createClient();
  const { data: sessionData } = await supabase.auth.getSession();
  const token = sessionData.session?.access_token;
  if (!token) return { error: "no_session" };

  const reason = field(formData, "reason").slice(0, 500);
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (!url) return { error: "unknown" };

  try {
    const res = await fetch(`${url}/functions/v1/delete-account`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ reason }),
    });
    if (!res.ok) return { error: "unknown" };
  } catch {
    return { error: "unknown" };
  }

  // Auth cookie now references a deleted user — clearing it locally so the
  // next request lands on the marketing home without a stale identity.
  await supabase.auth.signOut();
  redirect(localePath(formData, "/"));
}
