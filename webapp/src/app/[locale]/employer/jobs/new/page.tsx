import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { PostJobForm } from "@/components/employer/post-job-form";
import { Container } from "@/components/ui/container";
import { getCategories } from "@/lib/data/categories";
import { getEmployerStats, getMyCompany } from "@/lib/data/employer";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "employer" });
  return { title: t("postJob"), robots: { index: false } };
}

// Auth-dependent (prefills companyId for a signed-in employer) — render per
// request rather than prerendering a shared, sessionless page: without this,
// Next.js would statically build the page once with no user, permanently
// baking in companyId=null for every visitor, including real employers.
export const dynamic = "force-dynamic";

// Guest-first: a visitor (or a signed-in employer without a company yet) can
// fill this out freely. getMyCompany() is null-safe for both. Publishing asks
// for whatever's missing (auth and/or a company) at that point — see
// PostJobForm and createJob.
export default async function PostJobPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);

  const company = await getMyCompany();
  const t = await getTranslations("employer");
  const [categories, stats] = await Promise.all([
    getCategories(),
    company
      ? getEmployerStats(company.id)
      : Promise.resolve({
          totalJobs: 0,
          openJobs: 0,
          totalApplicants: 0,
          hasPublishedBefore: false,
        }),
  ]);

  return (
    <Container className="py-10">
      <h1 className="text-foreground mb-6 text-2xl font-bold">
        {t("postJob")}
      </h1>
      <PostJobForm
        companyId={company?.id ?? null}
        companyName={company?.name ?? null}
        categories={categories}
        hasPublishedBefore={stats.hasPublishedBefore}
      />
    </Container>
  );
}
