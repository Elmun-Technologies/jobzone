import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { ProfileForm } from "@/components/account/profile-form";
import { Container } from "@/components/ui/container";
import { getCurrentUser } from "@/lib/auth/user";
import { getMyProfileDetails } from "@/lib/data/profile";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "profile" });
  return { title: t("title"), robots: { index: false } };
}

const EMPTY = {
  fullName: "",
  headline: "",
  bio: "",
  phone: "",
  city: "",
  country: "",
};

export default async function EditProfilePage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);

  const user = await getCurrentUser();
  if (!user) redirect(`/${locale}/sign-in`);

  const t = await getTranslations("profile");
  const details = await getMyProfileDetails();

  return (
    <Container className="max-w-xl py-12">
      <h1 className="text-foreground mb-6 text-2xl font-bold">{t("title")}</h1>
      <ProfileForm initial={details ?? EMPTY} />
    </Container>
  );
}
