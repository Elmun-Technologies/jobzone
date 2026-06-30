import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { GoogleButton } from "@/components/auth/google-button";
import { SignUpForm } from "@/components/auth/sign-up-form";
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
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("auth");

  return (
    <Container className="flex max-w-md flex-col py-16">
      <h1 className="text-foreground mb-1 text-2xl font-bold">
        {t("createAccount")}
      </h1>
      <p className="text-muted-foreground mb-6 text-sm">
        {t("signUpSubtitle")}
      </p>

      <SignUpForm />

      <div className="text-muted-foreground my-4 flex items-center gap-3 text-xs">
        <span className="bg-border h-px flex-1" />
        {t("or")}
        <span className="bg-border h-px flex-1" />
      </div>

      <GoogleButton />

      <p className="text-muted-foreground mt-6 text-center text-sm">
        {t("haveAccount")}{" "}
        <Link
          href="/sign-in"
          className="text-primary font-semibold hover:underline"
        >
          {t("signIn")}
        </Link>
      </p>
    </Container>
  );
}
