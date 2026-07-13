import { BadgeCheck, MapPin, Sparkles } from "lucide-react";
import type { Metadata } from "next";
import { notFound, redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { MessageButton } from "@/components/chat/message-button";
import { InviteButton } from "@/components/employer/invite-button";
import { Container } from "@/components/ui/container";
import { EmptyState } from "@/components/ui/states";
import { requireEmployer } from "@/lib/auth/require-employer";
import {
  getJobTitleAndCompany,
  getRecommendedCandidates,
} from "@/lib/data/employer-applicants";
import { getMyCompany } from "@/lib/data/employer";
import { Link } from "@/i18n/navigation";

// Auth/session-dependent, per-request. Without this the page can be
// full-route-cached (getCurrentUser swallows cookies() so Next never sees
// the dynamic signal) and one visitor's render could be served to another.
export const dynamic = "force-dynamic";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "employer" });
  return { title: t("recommendedCandidates"), robots: { index: false } };
}

export default async function JobMatchesPage({
  params,
}: {
  params: Promise<{ locale: string; id: string }>;
}) {
  const { locale, id } = await params;
  setRequestLocale(locale);
  await requireEmployer(locale);

  // Independent reads; getRecommendedCandidates is RLS-gated (is_job_owner) so
  // it's safe before the company/ownership check below.
  const [company, job, candidates] = await Promise.all([
    getMyCompany(),
    getJobTitleAndCompany(id),
    getRecommendedCandidates(id),
  ]);
  if (!company) redirect(`/${locale}/employer/onboarding`);
  if (!job || job.companyId !== company.id) notFound();

  const t = await getTranslations("employer");

  const chipClass =
    "bg-muted text-foreground rounded-full px-2.5 py-1 text-xs font-medium";

  return (
    <Container className="max-w-3xl py-10">
      <Link
        href={`/employer/jobs/${id}/applicants`}
        className="text-muted-foreground hover:text-foreground text-sm"
      >
        ← {t("backToApplicants")}
      </Link>
      <h1 className="text-foreground mt-4 flex items-center gap-2 text-2xl font-bold">
        <Sparkles className="text-primary size-6" />
        {t("recommendedCandidates")}
      </h1>
      <p className="text-muted-foreground mt-1 text-sm">
        {job.title} · {t("recommendedSubtitle")}
      </p>

      {candidates.length === 0 ? (
        <div className="mt-8">
          <EmptyState title={t("noMatches")} description={t("noMatchesHint")} />
        </div>
      ) : (
        <ul className="mt-8 space-y-4">
          {candidates.map((c) => (
            <li
              key={c.id}
              className="border-border bg-card rounded-xl border p-4"
            >
              <div className="flex items-start justify-between gap-3">
                <div className="flex min-w-0 gap-3">
                  {c.avatarUrl ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={c.avatarUrl}
                      alt={c.name}
                      width={44}
                      height={44}
                      className="size-11 shrink-0 rounded-full object-cover"
                    />
                  ) : (
                    <div className="bg-primary text-primary-foreground flex size-11 shrink-0 items-center justify-center rounded-full font-bold">
                      {c.name.charAt(0).toUpperCase()}
                    </div>
                  )}
                  <div className="min-w-0">
                    <p className="text-foreground flex items-center gap-1 font-semibold">
                      <span className="truncate">{c.name}</span>
                      {c.workerVerified ? (
                        <BadgeCheck className="text-primary size-4 shrink-0" />
                      ) : null}
                    </p>
                    {c.headline ? (
                      <p className="text-muted-foreground truncate text-sm">
                        {c.headline}
                      </p>
                    ) : null}
                    {c.city ? (
                      <p className="text-muted-foreground mt-0.5 flex items-center gap-1 text-xs">
                        <MapPin className="size-3" /> {c.city}
                      </p>
                    ) : null}
                  </div>
                </div>
                <div className="flex shrink-0 flex-col items-end gap-2">
                  <InviteButton jobId={id} candidateId={c.id} />
                  <MessageButton profileId={c.id} />
                </div>
              </div>

              <div className="mt-3 flex flex-wrap gap-2">
                {c.sameCity ? (
                  <span className={chipClass}>{t("matchSameCity")}</span>
                ) : null}
                {c.roleMatch ? (
                  <span className={chipClass}>{t("matchRole")}</span>
                ) : null}
                {c.skillsMatched > 0 ? (
                  <span className={chipClass}>
                    {t("matchSkills", { count: c.skillsMatched })}
                  </span>
                ) : null}
              </div>
            </li>
          ))}
        </ul>
      )}
    </Container>
  );
}
