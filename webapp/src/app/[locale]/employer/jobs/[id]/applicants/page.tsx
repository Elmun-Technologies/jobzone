import type { Metadata } from "next";
import { notFound, redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { StatusSelect } from "@/components/employer/status-select";
import { MessageButton } from "@/components/chat/message-button";
import { Container } from "@/components/ui/container";
import { EmptyState } from "@/components/ui/states";
import { getMyCompany } from "@/lib/data/employer";
import {
  getJobApplicants,
  getJobTitleAndCompany,
} from "@/lib/data/employer-applicants";
import { requireEmployer } from "@/lib/auth/require-employer";
import { formatDate } from "@/lib/format";
import { Link } from "@/i18n/navigation";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "employer" });
  return { title: t("applicants"), robots: { index: false } };
}

export default async function JobApplicantsPage({
  params,
}: {
  params: Promise<{ locale: string; id: string }>;
}) {
  const { locale, id } = await params;
  setRequestLocale(locale);
  await requireEmployer(locale);

  const company = await getMyCompany();
  if (!company) redirect(`/${locale}/employer/onboarding`);

  const job = await getJobTitleAndCompany(id);
  if (!job || job.companyId !== company.id) notFound();

  const t = await getTranslations("employer");
  const applicants = await getJobApplicants(id);

  return (
    <Container className="max-w-3xl py-10">
      <p className="text-muted-foreground text-sm">{t("applicants")}</p>
      <h1 className="text-foreground mb-6 text-2xl font-bold">{job.title}</h1>

      {applicants.length === 0 ? (
        <EmptyState title={t("noApplicants")} />
      ) : (
        <ul className="space-y-4">
          {applicants.map((a) => (
            <li
              key={a.applicationId}
              className="border-border bg-card rounded-xl border p-4"
            >
              <div className="flex items-start justify-between gap-3">
                <div className="flex min-w-0 gap-3">
                  {a.avatarUrl ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={a.avatarUrl}
                      alt={a.name}
                      width={44}
                      height={44}
                      className="size-11 shrink-0 rounded-full object-cover"
                    />
                  ) : (
                    <div className="bg-primary text-primary-foreground flex size-11 shrink-0 items-center justify-center rounded-full font-bold">
                      {a.name.charAt(0).toUpperCase()}
                    </div>
                  )}
                  <div className="min-w-0">
                    <Link
                      href={`/employer/jobs/${id}/applicants/${a.applicationId}`}
                      className="text-foreground hover:text-primary block truncate font-semibold hover:underline"
                    >
                      {a.name}
                    </Link>
                    {a.headline ? (
                      <p className="text-muted-foreground truncate text-sm">
                        {a.headline}
                      </p>
                    ) : null}
                    {a.appliedAt ? (
                      <p className="text-muted-foreground text-xs">
                        {formatDate(a.appliedAt)}
                      </p>
                    ) : null}
                  </div>
                </div>
                <div className="flex shrink-0 flex-col items-end gap-2">
                  <StatusSelect
                    applicationId={a.applicationId}
                    initial={a.status}
                  />
                  <MessageButton profileId={a.applicantId} />
                </div>
              </div>

              {a.coverLetter ? (
                <p className="border-border text-muted-foreground mt-3 border-t pt-3 text-sm whitespace-pre-wrap">
                  {a.coverLetter}
                </p>
              ) : null}

              {Object.keys(a.answers).length > 0 ? (
                <ul className="border-border mt-3 space-y-2 border-t pt-3 text-sm">
                  {Object.entries(a.answers).map(([key, value]) => (
                    <li key={key}>
                      {job.questionLabels[key] ? (
                        <p className="text-muted-foreground text-xs">
                          {job.questionLabels[key]}
                        </p>
                      ) : null}
                      <p className="text-foreground">{String(value)}</p>
                    </li>
                  ))}
                </ul>
              ) : null}

              <div className="mt-3">
                <Link
                  href={`/employer/jobs/${id}/applicants/${a.applicationId}`}
                  className="text-primary text-sm font-medium hover:underline"
                >
                  {t("viewResume")} →
                </Link>
              </div>
            </li>
          ))}
        </ul>
      )}
    </Container>
  );
}
