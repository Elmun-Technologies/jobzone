import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { ResumeWizard } from "@/components/resume/resume-wizard";
import { Container } from "@/components/ui/container";
import { getMyResume } from "@/lib/data/resume";

// Auth-dependent (prefills from the signed-in user's profile) — render per
// request rather than prerendering a shared empty form.
export const dynamic = "force-dynamic";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "resume" });
  return { title: t("title"), robots: { index: false } };
}

export default async function NewResumePage({
  params,
  searchParams,
}: {
  params: Promise<{ locale: string }>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  const sp = await searchParams;
  // Quick-apply sends a seeker with no résumé here as
  // `?next=/uz/jobs/<id>/apply`. Reading it is what makes the wizard hand
  // them back to the job they were applying to; without it they finished
  // four steps and landed on recommendations with no application made.
  const next = typeof sp.next === "string" ? sp.next : undefined;
  const initial = await getMyResume();

  return (
    <Container className="py-10">
      <ResumeWizard initial={initial} next={next} />
    </Container>
  );
}
