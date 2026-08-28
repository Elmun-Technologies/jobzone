import { getTranslations, setRequestLocale } from "next-intl/server";
import { Sparkles } from "lucide-react";
import { ReactNode } from "react";

import { Container } from "@/components/ui/container";
import { getApplicantResume } from "@/lib/data/applicant-resume";
import { getApplicantForJob } from "@/lib/data/employer-applicants";
import { 
  type ApplicantExperience, 
  type ApplicantEducation 
} from "@/lib/data/types";

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <div className="space-y-3">
      <h2 className="text-foreground text-lg font-bold">{title}</h2>
      <div>{children}</div>
    </div>
  );
}

function yearRange(
  start: number | null,
  end: number | null,
  isCurrent: boolean,
  presentLabel: string,
) {
  if (!start) return "";
  const s = String(start);
  if (isCurrent) return `${s} — ${presentLabel}`;
  if (!end) return s;
  return `${s} — ${end}`;
}

export default async function ApplicantPage({
  params,
}: {
  params: Promise<{ locale: string; id: string; appId: string }>;
}) {
  const { locale, id, appId } = await params;
  setRequestLocale(locale);

  const t = await getTranslations("resume");
  // getApplicantForJob takes (jobId, applicationId)
  const application = await getApplicantForJob(id, appId);
  
  if (!application) return null;
  
  // getApplicantResume takes the applicant's profile ID
  const resume = await getApplicantResume(application.applicantId);

  return (
    <Container className="py-10">
      <div className="mx-auto max-w-3xl space-y-8">
        {/* Header */}
        <div>
          <h1 className="text-foreground text-3xl font-bold">
            {application.name}
          </h1>
          <p className="text-muted-foreground mt-1">
            {resume.experienceLevel ? t(`exp.${resume.experienceLevel}`) : ""}
            {resume.desiredPayMin ? ` · ${resume.desiredPayMin} ${resume.desiredPayCurrency}` : ""}
            {application.city ? ` · ${application.city}` : ""}
          </p>
        </div>

        {/* Résumé Summary */}
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

        {/* Experience */}
        {resume.experiences.length > 0 ? (
          <Section title={t("workExperience")}>
            <ul className="space-y-6">
              {resume.experiences.map((e: ApplicantExperience, i: number) => (
                <li key={i} className="border-border border-l-2 pl-4">
                  <p className="text-foreground font-semibold">{e.title}</p>
                  <p className="text-muted-foreground text-sm">
                    {e.companyName} · {yearRange(e.startYear, e.endYear, e.isCurrent, t("present"))}
                  </p>
                  {e.description ? (
                    <p className="text-foreground mt-2 text-sm whitespace-pre-wrap">
                      {e.description}
                    </p>
                  ) : null}
                </li>
              ))}
            </ul>
          </Section>
        ) : null}

        {/* Education */}
        {resume.educations.length > 0 ? (
          <Section title={t("education")}>
            <ul className="space-y-6">
              {resume.educations.map((e: ApplicantEducation, i: number) => (
                <li key={i} className="border-border border-l-2 pl-4">
                  <p className="text-foreground font-semibold">{e.degree}</p>
                  <p className="text-muted-foreground text-sm">
                    {e.school} · {yearRange(e.startYear, e.endYear, e.isCurrent, t("present"))}
                  </p>
                  {e.field ? (
                    <p className="text-muted-foreground mt-1 text-sm">{e.field}</p>
                  ) : null}
                </li>
              ))}
            </ul>
          </Section>
        ) : null}

        {/* Languages */}
        {Object.keys(resume.languages).length > 0 ? (
          <Section title={t("languages")}>
            <div className="flex flex-wrap gap-2">
              {Object.entries(resume.languages).map(([code, level]) => (
                <span
                  key={code}
                  className="bg-accent text-foreground rounded-lg px-3 py-1 text-sm font-medium"
                >
                  {code.toUpperCase()}: {String(level)}
                </span>
              ))}
            </div>
          </Section>
        ) : null}
      </div>
    </Container>
  );
}
