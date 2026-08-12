import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { AuthMethods } from "@/components/auth/auth-methods";
import { Container } from "@/components/ui/container";
import { Link } from "@/i18n/navigation";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "auth" });
  return { title: t("signIn"), robots: { index: false } };
}

export default async function SignInPage({
  params,
  searchParams,
}: {
  params: Promise<{ locale: string }>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  const sp = await searchParams;
  const next = typeof sp.next === "string" ? sp.next : undefined;
  const role = typeof sp.role === "string" ? sp.role : undefined;
  // Set by /auth/callback when an OAuth round-trip failed.
  const oauthFailed = sp.error === "oauth";
  // Set by signUpAction when email confirmation is pending.
  const confirmPending = sp.notice === "confirm";
  const t = await getTranslations("auth");

  // Carry next/role across to sign-up so a guest who came from an auth-last
  // flow (e.g. publishing a job) doesn't lose their way back if they don't
  // have an account yet.
  const signUpQuery = new URLSearchParams();
  if (next) signUpQuery.set("next", next);
  if (role) signUpQuery.set("role", role);
  const signUpHref = signUpQuery.size
    ? `/sign-up?${signUpQuery.toString()}`
    : "/sign-up";

  return (
    <Container className="flex max-w-md flex-col py-16">
      <h1 className="text-foreground mb-1 text-2xl font-bold">{t("signIn")}</h1>
      <p className="text-muted-foreground mb-6 text-sm">
        {t("signInSubtitle")}
      </p>

      {oauthFailed ? (
        <p className="border-destructive/30 bg-destructive/10 text-destructive mb-4 rounded-lg border px-3 py-2 text-sm font-medium">
          {t("errOauthCallback")}
        </p>
      ) : null}

      {confirmPending ? (
        <p className="border-primary/30 bg-accent text-accent-foreground mb-4 rounded-lg border px-3 py-2 text-sm font-medium">
          {t("confirmEmailNotice")}
        </p>
      ) : null}

      <AuthMethods mode="signIn" next={next} />

      <p className="text-muted-foreground mt-6 text-center text-sm">
        {t("noAccount")}{" "}
        <Link
          href={signUpHref}
          className="text-foreground font-semibold hover:underline"
        >
          {t("createAccount")}
        </Link>
      </p>
    </Container>
  );
}
