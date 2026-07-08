import { BadgeCheck, MapPin, Sparkles } from "lucide-react";
import type { Metadata } from "next";
import { notFound, redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";
import type { ReactNode } from "react";

import { MessageButton } from "@/components/chat/message-button";
import { StatusSelect } from "@/components/employer/status-select";
import { Container } from "@/components/ui/container";
import { requireEmployer } from "@/lib/auth/require-employer";
import { getApplicantResume } from "@/lib/data/applicant-resume";
import {
  getApplicantForJob,
  getJobTitleAndCompany,
} from "@/lib/data/employer-applicants";
import { getMyCompany } from "@/lib/data/employer";
import { formatDate, groupNumber } from "@/lib/format";
import { Link } from "@/i18n/navigation";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "employer" });
  return { title: t("applicantResume"), robots: { index: false } };
}

// Fixed language chips the wizard offers by code; anything else the seeker added
// by name (rendered as-is). Levels come from the shared `resume` namespace.
const FIXED_LANGS = new Set(["ru", "en", "tr", "tg", "uz"]);
const EXP_KEYS = new Set(["none", "under_1", "1_3", "3_5", "5_plus"]);
const LEVEL_KEYS = new Set(["none", "a1_a2", "b1_b2", "c1_c2", "native"]);

function yearRange(
  startYear: string,
  endYear: string,
  isCurrent: boolean,
  present: string,
): string | null {
  const end = isCurrent ? present : endYear;
  if (startYear && end) return `${startYear} – ${end}`;
  return startYear || end || null;
}

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="border-border bg-card rounded-2xl border p-5">
      <h2 className="text-foreground mb-3 font-semibold">{title}</h2>
      {children}
    </section>
  );
}

export default async function ApplicantResumePage({
  params,
}: {
  params: Promise<{ locale: string; id: string; appId: string }>;
}) {
  const { locale, id, appId } = await params;
  setRequestLocale(locale);
  await requireEmployer(locale);

  const company = await getMyCompany();
  if (!company) redirect(`/${locale}/employer/onboarding`);

  const job = await getJobTitleAndCompany(id);
  if (!job || job.companyId !== company.id) notFound();

  const applicant = await getApplicantForJob(id, appId);
  if (!applicant) notFound();

  const resume = await getApplicantResume(applicant.applicantId);

  const t = await getTranslations("employer");
  const tr = await getTranslations("resume");

  const salaryLabel = resume.expectedSalary
    ? `${groupNumber(Number(resume.expectedSalary))} ${
        resume.currency === "UZS" ? "so'm" : resume.currency
      }`
    : null;

  const chipClass =
    "bg-muted text-foreground rounded-full px-3 py-1 text-xs font-medium";

  return (
    <Container className="max-w-3xl py-10">
      <Link
        href={`/employer/jobs/${id}/applicants`}
        className="text-muted-foreground hover:text-foreground text-sm"
      >
        ← {t("backToApplicants")}
      </Link>
      <p className="text-muted-foreground mt-4 text-sm">{job.title}</p>

      {/* Applicant header + actions */}
      <div className="border-border bg-card mt-2 rounded-2xl border p-5">
        <div className="flex items-start justify-between gap-3">
          <div className="flex min-w-0 gap-3">
            {applicant.avatarUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={applicant.avatarUrl}
                alt={applicant.name}
                width={56}
                height={56}
                className="size-14 shrink-0 rounded-full object-cover"
              />
            ) : (
              <div className="bg-primary text-primary-foreground flex size-14 shrink-0 items-center justify-center rounded-full text-xl font-bold">
                {applicant.name.charAt(0).toUpperCase()}
              </div>
            )}
            <div className="min-w-0">
              <p className="text-foreground flex items-center gap-1 text-lg font-bold">
                <span className="truncate">{applicant.name}</span>
                {applicant.workerVerified ? (
                  <BadgeCheck className="text-primary size-4 shrink-0" />
                ) : null}
              </p>
              {applicant.headline ? (
                <p className="text-muted-foreground truncate text-sm">
                  {applicant.headline}
                </p>
              ) : null}
              <div className="text-muted-foreground mt-1 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs">
                {applicant.city ? (
                  <span className="flex items-center gap-1">
                    <MapPin className="size-3" /> {applicant.city}
                  </span>
                ) : null}
                {applicant.appliedAt ? (
                  <span>
                    {t("appliedOn")}: {formatDate(applicant.appliedAt)}
                  </span>
                ) : null}
              </div>
            </div>
          </div>
          <div className="flex shrink-0 flex-col items-end gap-2">
            <StatusSelect
              applicationId={applicant.applicationId}
              initial={applicant.status}
            />
            <MessageButton profileId={applicant.applicantId} />
          </div>
        </div>

        {(resume.experienceLevel && EXP_KEYS.has(resume.experienceLevel)) ||
        salaryLabel ? (
          <div className="mt-4 flex flex-wrap gap-2">
            {resume.experienceLevel && EXP_KEYS.has(resume.experienceLevel) ? (
              <span className={chipClass}>
                {t("expLevel")}: {tr(`exp.${resume.experienceLevel}`)}
              </span>
            ) : null}
            {salaryLabel ? (
              <span className={chipClass}>
                {t("expectedSalary")}: {salaryLabel}
              </span>
            ) : null}
          </div>
        ) : null}
      </div>

      <div className="mt-6 space-y-6">
        {/* Cover letter */}
        {applicant.coverLetter ? (
          <Section title={t("coverLetter")}>
            <p className="text-muted-foreground text-sm whitespace-pre-wrap">
              {applicant.coverLetter}
            </p>
          </Section>
        ) : null}

        {/* Screening answers */}
        {Object.keys(applicant.answers).length > 0 ? (
          <Section title={t("screeningAnswers")}>
            <ul className="space-y-3">
              {Object.entries(applicant.answers).map(([key, value]) => (
                <li key={key}>
                  {job.questionLabels[key] ? (
                    <p className="text-muted-foreground text-xs">
                      {job.questionLabels[key]}
                    </p>
                  ) : null}
                  <p className="text-foreground text-sm">{String(value)}</p>
                </li>
              ))}
            </ul>
          </Section>
        ) : null}

        {/* Résumé */}
        {resume.summary ? (
          <Section title={t("aboutMe")}>
            {resume.summaryAiGenerated ? (
              <span className="border-primary/40 text-muted-foreground mb-2 inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-xs">
                <Sparkles className="size-3" /> {t("aiAssisted")}
              </span>
            ) : null}
            <p className="text-foreground text-sm whitespace-pre-wrap">
              {resume.summary}
            </p>
          </Section>
        ) : null}

        {resume.experiences.length > 0 ? (
          <Section title={t("workExperience")}>
            <ul className="space-y-4">
              {resume.experiences.map((e, i) => {
                const range = yearRange(
                  e.startYear,
                  e.endYear,
                  e.isCurrent,
                  t("present"),
                );
                return (
                  <li key={i} className="border-border border-l-2 pl-3">
                    <p className="text-foreground font-medium">{e.title}</p>
                    {e.companyName ? (
                      <p className="text-muted-foreground text-sm">
                        {e.companyName}
                      </p>
                    ) : null}
                    {range ? (
                      <p className="text-muted-foreground text-xs">{range}</p>
                    ) : null}
                    {e.description ? (
                      <p className="text-foreground mt-1 text-sm whitespace-pre-wrap">
                        {e.description}
                      </p>
                    ) : null}
                  </li>
                );
              })}
            </ul>
          </Section>
        ) : null}

        {resume.educations.length > 0 ? (
          <Section title={t("educationTitle")}>
            <ul className="space-y-4">
              {resume.educations.map((e, i) => {
                const range = yearRange(
                  e.startYear,
                  e.endYear,
                  e.isCurrent,
                  t("present"),
                );
                const detail = [e.degree, e.field].filter(Boolean).join(", ");
                return (
                  <li key={i} className="border-border border-l-2 pl-3">
                    <p className="text-foreground font-medium">{e.school}</p>
                    {detail ? (
                      <p className="text-muted-foreground text-sm">{detail}</p>
                    ) : null}
                    {range ? (
                      <p className="text-muted-foreground text-xs">{range}</p>
                    ) : null}
                  </li>
                );
              })}
            </ul>
          </Section>
        ) : null}

        {resume.certificates.length > 0 ? (
          <Section title={t("certificates")}>
            <ul className="space-y-3">
              {resume.certificates.map((c, i) => (
                <li key={i}>
                  <p className="text-foreground font-medium">{c.name}</p>
                  <p className="text-muted-foreground text-xs">
                    {[
                      c.issuer,
                      c.issuedYear ? `${t("issued")}: ${c.issuedYear}` : "",
                      c.expiryYear ? `${t("expires")}: ${c.expiryYear}` : "",
                    ]
                      .filter(Boolean)
                      .join(" · ")}
                  </p>
                </li>
              ))}
            </ul>
          </Section>
        ) : null}

        {Object.keys(resume.languages).length > 0 ? (
          <Section title={t("languages")}>
            <ul className="flex flex-wrap gap-2">
              {Object.entries(resume.languages).map(([code, level]) => {
                const name = FIXED_LANGS.has(code) ? tr(`lang.${code}`) : code;
                const lvl = LEVEL_KEYS.has(level)
                  ? tr(`level.${level}`)
                  : level;
                return (
                  <li key={code} className={chipClass}>
                    {name}
                    {lvl ? (
                      <span className="text-muted-foreground"> · {lvl}</span>
                    ) : null}
                  </li>
                );
              })}
            </ul>
          </Section>
        ) : null}

        {resume.skills.length > 0 ? (
          <Section title={t("skills")}>
            <ul className="flex flex-wrap gap-2">
              {resume.skills.map((s, i) => (
                <li key={i} className={chipClass}>
                  {s}
                </li>
              ))}
            </ul>
          </Section>
        ) : null}

        {!resume.hasAny &&
        !applicant.coverLetter &&
        Object.keys(applicant.answers).length === 0 ? (
          <p className="text-muted-foreground text-sm">{t("noResumeYet")}</p>
        ) : null}
      </div>
    </Container>
  );
}
