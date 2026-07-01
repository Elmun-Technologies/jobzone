"use client";

import { useLocale, useTranslations } from "next-intl";
import { useRouter } from "next/navigation";
import { useActionState, useEffect, useRef, useState } from "react";

import { createJob, type JobFormState } from "@/lib/actions/employer";
import type { JobCategory } from "@/lib/data/types";
import { cn } from "@/lib/utils";

import { ScreeningEditor, type StashedQuestion } from "./screening-editor";

const inputClass =
  "h-11 w-full rounded-lg border border-border bg-background px-3 text-sm text-foreground outline-none focus-visible:ring-2 focus-visible:ring-ring";
const areaClass =
  "w-full rounded-lg border border-border bg-background px-3 py-2 text-sm text-foreground outline-none focus-visible:ring-2 focus-visible:ring-ring";

const JOB_TYPES = [
  "full_time",
  "part_time",
  "contract",
  "temporary",
  "internship",
  "rotational",
];
const WORKING_MODELS = ["onsite", "remote", "hybrid"];
const EXPERIENCE = ["entry", "mid", "senior", "lead"];
const SCHEDULES = ["5_2", "6_1", "4_4", "2_2", "custom"];
const PERIODS = ["hour", "day", "week", "month", "year"];

// Where an in-progress vacancy is parked while a guest signs in — and/or a
// brand-new employer creates their company — at publish-time.
const STASH_KEY = "yolla-post-job-draft";

interface JobDraft {
  title: string;
  description: string;
  requirements: string;
  responsibilities: string;
  benefits: string;
  categoryId: string;
  salaryMin: string;
  salaryMax: string;
  currency: string;
  salaryPeriod: string;
  city: string;
  addressText: string;
  jobType: string;
  workingModel: string;
  experienceLevel: string;
  schedulePattern: string;
  nightShift: boolean;
  contactPhone: string;
  showPhone: boolean;
  requireCoverLetter: boolean;
  womenFriendly: boolean;
  disabilityFriendly: boolean;
  screeningQuestions: StashedQuestion[];
}

function draftFromFormData(data: FormData): JobDraft {
  const str = (k: string) => (data.get(k) ?? "").toString();
  const bool = (k: string) => data.get(k) === "1";
  let screeningQuestions: StashedQuestion[] = [];
  try {
    screeningQuestions = JSON.parse(str("screeningQuestions") || "[]");
  } catch {
    screeningQuestions = [];
  }
  return {
    title: str("title"),
    description: str("description"),
    requirements: str("requirements"),
    responsibilities: str("responsibilities"),
    benefits: str("benefits"),
    categoryId: str("categoryId"),
    salaryMin: str("salaryMin"),
    salaryMax: str("salaryMax"),
    currency: str("currency") || "UZS",
    salaryPeriod: str("salaryPeriod") || "month",
    city: str("city"),
    addressText: str("addressText"),
    jobType: str("jobType"),
    workingModel: str("workingModel"),
    experienceLevel: str("experienceLevel"),
    schedulePattern: str("schedulePattern"),
    nightShift: bool("nightShift"),
    contactPhone: str("contactPhone"),
    showPhone: bool("showPhone"),
    requireCoverLetter: bool("requireCoverLetter"),
    womenFriendly: bool("womenFriendly"),
    disabilityFriendly: bool("disabilityFriendly"),
    screeningQuestions,
  };
}

function Section({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle?: string;
  children: React.ReactNode;
}) {
  return (
    <section className="border-border bg-card rounded-2xl border p-5">
      <h2 className="text-foreground text-lg font-bold">{title}</h2>
      {subtitle ? (
        <p className="text-muted-foreground mt-0.5 mb-4 text-sm">{subtitle}</p>
      ) : (
        <div className="mb-4" />
      )}
      <div className="space-y-4">{children}</div>
    </section>
  );
}

function Labeled({
  label,
  required,
  children,
}: {
  label: string;
  required?: boolean;
  children: React.ReactNode;
}) {
  return (
    <label className="block">
      <span className="text-foreground mb-1.5 block text-sm font-medium">
        {label}
        {required ? <span className="text-primary"> *</span> : null}
      </span>
      {children}
    </label>
  );
}

/** Hidden-radio-backed single-select chip row (posts with the form). */
function ChipRadio({
  name,
  options,
  defaultValue = "",
}: {
  name: string;
  options: { value: string; label: string }[];
  defaultValue?: string;
}) {
  return (
    <div className="flex flex-wrap gap-2">
      {options.map((o) => (
        <label key={o.value} className="cursor-pointer">
          <input
            type="radio"
            name={name}
            value={o.value}
            defaultChecked={defaultValue === o.value}
            className="peer sr-only"
          />
          <span className="border-border peer-checked:border-primary peer-checked:bg-primary peer-checked:text-primary-foreground hover:border-primary/40 inline-block rounded-full border px-4 py-2 text-sm font-medium transition-colors">
            {o.label}
          </span>
        </label>
      ))}
    </div>
  );
}

function Check({
  name,
  label,
  defaultChecked,
}: {
  name: string;
  label: string;
  defaultChecked?: boolean;
}) {
  return (
    <label className="text-foreground flex items-center gap-2 text-sm">
      <input
        type="checkbox"
        name={name}
        value="1"
        defaultChecked={defaultChecked}
        className="size-4"
      />
      {label}
    </label>
  );
}

/**
 * Guest-first: a visitor can fill this out without an account or a company.
 * Publishing/saving asks for what's missing at that point — sign-in
 * (`state.signedOut`) and/or company creation (`state.noCompany`) — and comes
 * back here with the draft restored, so nothing typed is lost.
 */
export function PostJobForm({
  companyId,
  categories,
}: {
  companyId: string | null;
  categories: JobCategory[];
}) {
  const t = useTranslations("employer");
  const tp = useTranslations("employer.post");
  const tj = useTranslations("jobs");
  const locale = useLocale();
  const router = useRouter();
  const [state, action, pending] = useActionState<JobFormState, FormData>(
    createJob,
    {},
  );
  const [restored, setRestored] = useState<JobDraft | null>(null);
  const formRef = useRef<HTMLFormElement>(null);

  useEffect(() => {
    const saved = sessionStorage.getItem(STASH_KEY);
    if (!saved) return;
    sessionStorage.removeItem(STASH_KEY);
    // Restoring client-only storage after mount is intentional here (a lazy
    // initializer would desync SSR hydration).
    try {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setRestored(JSON.parse(saved) as JobDraft);
    } catch {
      // Ignore a malformed stash.
    }
  }, []);

  useEffect(() => {
    if (!state.signedOut && !state.noCompany) return;
    if (!formRef.current) return;
    sessionStorage.setItem(
      STASH_KEY,
      JSON.stringify(draftFromFormData(new FormData(formRef.current))),
    );
    const postJobPath = `/${locale}/employer/jobs/new`;
    if (state.signedOut) {
      router.push(
        `/sign-in?next=${encodeURIComponent(postJobPath)}&role=employer`,
      );
    } else {
      router.push(
        `/employer/onboarding?next=${encodeURIComponent(postJobPath)}`,
      );
    }
  }, [state.signedOut, state.noCompany, locale, router]);

  const d = restored;

  return (
    <form
      // Uncontrolled fields only read defaultValue/defaultChecked on mount, so
      // a fresh key forces a remount once the restored draft lands (a moment
      // after the initial paint) — otherwise it would never reach the DOM.
      key={restored ? "restored" : "initial"}
      ref={formRef}
      action={action}
      className="grid gap-6 lg:grid-cols-[1fr_280px] lg:items-start"
    >
      <input type="hidden" name="locale" value={locale} />
      {companyId ? (
        <input type="hidden" name="companyId" value={companyId} />
      ) : null}

      <div className="space-y-6">
        <Section title={tp("sectionBasic")} subtitle={tp("sectionBasicSub")}>
          <Labeled label={t("jobTitle")} required>
            <input
              name="title"
              required
              defaultValue={d?.title}
              placeholder={tp("titleHint")}
              className={inputClass}
            />
          </Labeled>
          <Labeled label={t("jobDescription")}>
            <textarea
              name="description"
              rows={5}
              defaultValue={d?.description}
              className={areaClass}
            />
          </Labeled>
          <Labeled label={tp("requirements")}>
            <textarea
              name="requirements"
              rows={3}
              defaultValue={d?.requirements}
              className={areaClass}
            />
          </Labeled>
          <Labeled label={tp("responsibilities")}>
            <textarea
              name="responsibilities"
              rows={3}
              defaultValue={d?.responsibilities}
              className={areaClass}
            />
          </Labeled>
          <Labeled label={tp("benefits")}>
            <textarea
              name="benefits"
              rows={3}
              defaultValue={d?.benefits}
              className={areaClass}
            />
          </Labeled>
          <Labeled label={t("category")}>
            <select
              name="categoryId"
              defaultValue={d?.categoryId ?? ""}
              className={inputClass}
            >
              <option value="">—</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </Labeled>
        </Section>

        <Section title={tp("sectionSalary")}>
          <div className="grid gap-4 sm:grid-cols-3">
            <Labeled label={t("salaryMin")}>
              <input
                name="salaryMin"
                type="number"
                inputMode="numeric"
                defaultValue={d?.salaryMin}
                className={inputClass}
              />
            </Labeled>
            <Labeled label={t("salaryMax")}>
              <input
                name="salaryMax"
                type="number"
                inputMode="numeric"
                defaultValue={d?.salaryMax}
                className={inputClass}
              />
            </Labeled>
            <Labeled label={t("currency")}>
              <select
                name="currency"
                defaultValue={d?.currency ?? "UZS"}
                className={inputClass}
              >
                <option value="UZS">UZS</option>
                <option value="USD">USD</option>
              </select>
            </Labeled>
          </div>
          <Labeled label={tp("salaryPeriod")}>
            <select
              name="salaryPeriod"
              defaultValue={d?.salaryPeriod ?? "month"}
              className={inputClass}
            >
              {PERIODS.map((p) => (
                <option key={p} value={p}>
                  {tp(`period.${p}`)}
                </option>
              ))}
            </select>
          </Labeled>
        </Section>

        <Section
          title={tp("sectionLocation")}
          subtitle={tp("sectionLocationSub")}
        >
          <Labeled label={t("city")}>
            <input name="city" defaultValue={d?.city} className={inputClass} />
          </Labeled>
          <Labeled label={tp("address")}>
            <input
              name="addressText"
              defaultValue={d?.addressText}
              placeholder={tp("addressHint")}
              className={inputClass}
            />
          </Labeled>
        </Section>

        <Section
          title={tp("sectionEmployment")}
          subtitle={tp("sectionEmploymentSub")}
        >
          <Labeled label={tj("jobType")}>
            <ChipRadio
              name="jobType"
              defaultValue={d?.jobType}
              options={JOB_TYPES.map((v) => ({
                value: v,
                label: tj(`type.${v}`),
              }))}
            />
          </Labeled>
          <Labeled label={tj("workingModel")}>
            <ChipRadio
              name="workingModel"
              defaultValue={d?.workingModel}
              options={WORKING_MODELS.map((v) => ({
                value: v,
                label: tj(`model.${v}`),
              }))}
            />
          </Labeled>
          <Labeled label={t("experience")}>
            <ChipRadio
              name="experienceLevel"
              defaultValue={d?.experienceLevel}
              options={EXPERIENCE.map((v) => ({
                value: v,
                label: t(`exp.${v}`),
              }))}
            />
          </Labeled>
          <Labeled label={tp("schedule")}>
            <ChipRadio
              name="schedulePattern"
              defaultValue={d?.schedulePattern}
              options={SCHEDULES.map((v) => ({
                value: v,
                label: tp(`sched.${v}`),
              }))}
            />
          </Labeled>
          <Check
            name="nightShift"
            label={tp("nightShift")}
            defaultChecked={d?.nightShift}
          />
        </Section>

        <Section
          title={tp("sectionContacts")}
          subtitle={tp("sectionContactsSub")}
        >
          <Labeled label={tp("contactPhone")}>
            <input
              name="contactPhone"
              type="tel"
              defaultValue={d?.contactPhone}
              placeholder="+998 90 123 45 67"
              className={inputClass}
            />
          </Labeled>
          <Check
            name="showPhone"
            label={tp("showPhone")}
            defaultChecked={d?.showPhone}
          />
          <Check
            name="requireCoverLetter"
            label={tp("requireCoverLetter")}
            defaultChecked={d?.requireCoverLetter}
          />
          <Check
            name="womenFriendly"
            label={tp("womenFriendly")}
            defaultChecked={d?.womenFriendly}
          />
          <Check
            name="disabilityFriendly"
            label={tp("disabilityFriendly")}
            defaultChecked={d?.disabilityFriendly}
          />
        </Section>

        <ScreeningEditor initialQuestions={d?.screeningQuestions} />

        {state.error ? (
          <p className="text-destructive text-sm">{t("errUnknown")}</p>
        ) : null}
      </div>

      {/* Actions */}
      <aside className="border-border bg-card space-y-2 rounded-2xl border p-4 lg:sticky lg:top-20">
        <button
          type="submit"
          name="status"
          value="open"
          disabled={pending}
          className="bg-primary text-primary-foreground h-11 w-full rounded-lg text-sm font-bold transition-opacity hover:opacity-90 disabled:opacity-60"
        >
          {t("publishJob")}
        </button>
        <button
          type="submit"
          name="status"
          value="draft"
          disabled={pending}
          className={cn(
            "border-border text-foreground hover:bg-muted h-11 w-full rounded-lg border text-sm font-semibold transition-colors disabled:opacity-60",
          )}
        >
          {tp("saveDraft")}
        </button>
      </aside>
    </form>
  );
}
