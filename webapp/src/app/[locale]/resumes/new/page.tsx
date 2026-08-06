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
  const initial = await getMyResume();
  const sp = await searchParams;
  // Quick-apply sends a seeker with no résumé here before it can apply for
  // them, carrying the job's apply page as `next` — read but never wired
  // through, so finishing the résumé always dropped the seeker on a generic
  // recommendations list instead of back on the job they tapped Apply on.
  // Validated with safeNext() client-side, right before it's used.
  const next = typeof sp.next === "string" ? sp.next : undefined;

  return (
    <Container className="py-10">
      <ResumeWizard initial={initial} applyNext={next} />
    </Container>
  );
}
