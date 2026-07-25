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
  return { title: t("createAccount"), robots: { index: false } };
}

export default async function SignUpPage({
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
  const t = await getTranslations("auth");

  // Carry next/role across to sign-in for the reverse switch (e.g. a guest
  // who already has an account clicks "create account" by mistake).
  const signInQuery = new URLSearchParams();
  if (next) signInQuery.set("next", next);
  if (role) signInQuery.set("role", role);
  const signInHref = signInQuery.size
    ? `/sign-in?${signInQuery.toString()}`
    : "/sign-in";

  return (
    <Container className="flex max-w-md flex-col py-16">
      <h1 className="text-foreground mb-1 text-2xl font-bold">
        {t("createAccount")}
      </h1>
      <p className="text-muted-foreground mb-6 text-sm">
        {t("signUpSubtitle")}
      </p>

      <AuthMethods mode="signUp" next={next} initialRole={role} />

      <p className="text-muted-foreground mt-6 text-center text-sm">
        {t("haveAccount")}{" "}
        <Link
          href={signInHref}
          className="text-primary font-semibold hover:underline"
        >
          {t("signIn")}
        </Link>
      </p>
    </Container>
  );
}
