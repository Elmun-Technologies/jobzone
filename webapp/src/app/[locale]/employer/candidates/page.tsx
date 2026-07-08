import { Briefcase } from "lucide-react";
import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { ApplicationStatusPill } from "@/components/employer/application-status-pill";
import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { EmptyState } from "@/components/ui/states";
import { getMyCompany } from "@/lib/data/employer";
import { getCompanyCandidates } from "@/lib/data/employer-applicants";
import { requireEmployer } from "@/lib/auth/require-employer";
import { formatDate } from "@/lib/format";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "nav" });
  return { title: t("candidates"), robots: { index: false } };
}

// Auth-gated, per-employer page (reads the session via requireEmployer). Render
// per request — getCurrentUser()'s try/catch swallows the cookies() dynamic
// signal, so without this Next.js would prerender one shared, logged-out copy.
export const dynamic = "force-dynamic";

export default async function CandidatesPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  await requireEmployer(locale);

  const company = await getMyCompany();
  if (!company) redirect(`/${locale}/employer/onboarding`);

  const t = await getTranslations("employer.candidates");
  const ts = await getTranslations("applications.status");
  const candidates = await getCompanyCandidates(company.id);

  return (
    <Container className="max-w-3xl py-10">
      <div className="mb-6 flex items-center justify-between gap-3">
        <h1 className="text-foreground text-2xl font-bold">{t("title")}</h1>
        <Link
          href="/employer/jobs"
          className={cn(buttonVariants({ variant: "outline", size: "sm" }))}
        >
          {t("myJobs")}
        </Link>
      </div>

      {candidates.length === 0 ? (
        <EmptyState
          icon={<Briefcase className="size-6" />}
          title={t("empty")}
          description={t("emptyHint")}
        />
      ) : (
        <ul className="space-y-3">
          {candidates.map((c) => (
            <li key={c.applicationId}>
              <Link
                href={`/employer/jobs/${c.jobId}/applicants`}
                className="border-border bg-card hover:border-primary/40 flex items-center gap-3 rounded-xl border p-4 transition-colors"
              >
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
                  <div className="bg-muted text-foreground flex size-11 shrink-0 items-center justify-center rounded-full text-base font-bold">
                    {c.name.charAt(0).toUpperCase()}
                  </div>
                )}
                <div className="min-w-0 flex-1">
                  <p className="text-foreground truncate font-semibold">
                    {c.name}
                  </p>
                  <p className="text-muted-foreground truncate text-sm">
                    {c.headline ? `${c.headline} · ` : ""}
                    {t("appliedTo", { job: c.jobTitle })}
                  </p>
                  {c.appliedAt ? (
                    <p className="text-muted-foreground text-xs">
                      {formatDate(c.appliedAt)}
                    </p>
                  ) : null}
                </div>
                <ApplicationStatusPill
                  status={c.status}
                  label={ts.has(c.status) ? ts(c.status) : c.status}
                />
              </Link>
            </li>
          ))}
        </ul>
      )}
    </Container>
  );
}
