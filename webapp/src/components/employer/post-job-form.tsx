"use client";

import { Check as CheckIcon, Sparkles } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { useRouter } from "next/navigation";
import { useActionState, useEffect, useRef, useState } from "react";

import { generateJobContent } from "@/lib/actions/ai-content";
import { createJob, type JobFormState } from "@/lib/actions/employer";
import type { JobCategory } from "@/lib/data/types";
import { groupNumber } from "@/lib/format";
import { PROFESSIONS, suggestCategorySlug } from "@/lib/professions";
import { cn } from "@/lib/utils";

import { LocationPicker } from "../map/location-picker";
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
  lat: number | null;
  lng: number | null;
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
  const num = (k: string) => {
    const v = str(k);
    return v ? Number(v) : null;
  };
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
    lat: num("lat"),
    lng: num("lng"),
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

interface PreviewData {
  title: string;
  category: string | null;
  salary: string | null;
  location: string | null;
  employment: string[];
  flags: string[];
  description: string;
  requirements: string;
  responsibilities: string;
  benefits: string;
}

/**
 * Guest-first: a visitor can fill this out without an account or a company.
 * Publishing/saving asks for what's missing at that point — sign-in
 * (`state.signedOut`) and/or company creation (`state.noCompany`) — and comes
 * back here with the draft restored, so nothing typed is lost.
 *
 * The form is a step-by-step wizard: the field sections all stay mounted (so
 * FormData + the draft stash keep working) but only the active step is shown,
 * ending in a live preview before Publish / Save draft.
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
  const categoryRef = useRef<HTMLSelectElement>(null);
  const stepAreaRef = useRef<HTMLDivElement>(null);
  const [step, setStep] = useState(0);
  const [titleError, setTitleError] = useState(false);
  const [preview, setPreview] = useState<PreviewData | null>(null);
  const [aiPending, setAiPending] = useState(false);
  const [aiError, setAiError] = useState(false);
  const [pin, setPin] = useState<{ lat: number; lng: number } | null>(null);
  const [cityText, setCityText] = useState("");

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

  // The map pin and city hint are React-controlled (not uncontrolled DOM
  // fields), so a restored draft has to be mirrored into state explicitly.
  useEffect(() => {
    if (!restored) return;
    if (restored.lat != null && restored.lng != null) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setPin({ lat: restored.lat, lng: restored.lng });
    }
    if (restored.city) setCityText(restored.city);
  }, [restored]);

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

  // Re-trigger the step-fade animation on each step change without remounting
  // the (uncontrolled) fields, which would wipe what the user typed.
  useEffect(() => {
    const el = stepAreaRef.current;
    if (!el) return;
    el.classList.remove("wizfade");
    void el.offsetWidth; // force reflow so the animation restarts
    el.classList.add("wizfade");
  }, [step]);

  const d = restored;
  const steps = [
    tp("stepBasics"),
    tp("stepDetails"),
    tp("stepLocation"),
    tp("stepSettings"),
    tp("stepPreview"),
  ];
  const last = steps.length - 1;

  function buildPreview(): PreviewData {
    const fd = new FormData(formRef.current!);
    const g = (k: string) => (fd.get(k) ?? "").toString().trim();
    const catId = g("categoryId");
    const min = g("salaryMin");
    const max = g("salaryMax");
    const cur = g("currency") || "UZS";
    const per = g("salaryPeriod");
    let salary: string | null = null;
    if (min || max) {
      const amounts = [min, max]
        .filter(Boolean)
        .map((n) => groupNumber(Number(n)))
        .join(" – ");
      const unit = cur === "UZS" ? "so'm" : cur;
      salary = `${amounts} ${unit}${per ? ` / ${tp(`period.${per}`)}` : ""}`;
    }
    const employment = [
      g("jobType") && tj(`type.${g("jobType")}`),
      g("workingModel") && tj(`model.${g("workingModel")}`),
      g("experienceLevel") && t(`exp.${g("experienceLevel")}`),
      g("schedulePattern") && tp(`sched.${g("schedulePattern")}`),
    ].filter(Boolean) as string[];
    const flags = [
      fd.get("nightShift") === "1" && tp("nightShift"),
      fd.get("womenFriendly") === "1" && tp("womenFriendly"),
      fd.get("disabilityFriendly") === "1" && tp("disabilityFriendly"),
      g("lat") && g("lng") && tp("pinSet"),
    ].filter(Boolean) as string[];
    return {
      title: g("title"),
      category: categories.find((c) => c.id === catId)?.name ?? null,
      salary,
      location:
        [g("city"), g("addressText")].filter(Boolean).join(", ") || null,
      employment,
      flags,
      description: g("description"),
      requirements: g("requirements"),
      responsibilities: g("responsibilities"),
      benefits: g("benefits"),
    };
  }

  async function fillWithAi() {
    const form = formRef.current;
    if (!form) return;
    const title = (
      form.elements.namedItem("title") as HTMLInputElement | null
    )?.value.trim();
    if (!title) {
      setTitleError(true);
      return;
    }
    setAiPending(true);
    setAiError(false);
    try {
      const catId = (
        form.elements.namedItem("categoryId") as HTMLSelectElement | null
      )?.value;
      const category = categories.find((c) => c.id === catId)?.name ?? null;
      const res = await generateJobContent({ title, category, locale });
      const set = (name: string, val: string) => {
        const el = form.elements.namedItem(name) as HTMLTextAreaElement | null;
        if (el && val) el.value = val;
      };
      set("description", res.description);
      set("responsibilities", res.responsibilities);
      set("requirements", res.requirements);
      set("benefits", res.benefits);
    } catch {
      setAiError(true);
    } finally {
      setAiPending(false);
    }
  }

  function goNext() {
    if (step === 0) {
      const el = formRef.current?.elements.namedItem(
        "title",
      ) as HTMLInputElement | null;
      if (!el?.value.trim()) {
        setTitleError(true);
        el?.focus();
        return;
      }
      setTitleError(false);
    }
    if (step === last - 1) setPreview(buildPreview());
    setStep((s) => Math.min(s + 1, last));
  }

  return (
    <form
      // Uncontrolled fields only read defaultValue/defaultChecked on mount, so
      // a fresh key forces a remount once the restored draft lands (a moment
      // after the initial paint) — otherwise it would never reach the DOM.
      key={restored ? "restored" : "initial"}
      ref={formRef}
      action={action}
      className="mx-auto max-w-2xl"
    >
      <input type="hidden" name="locale" value={locale} />
      {companyId ? (
        <input type="hidden" name="companyId" value={companyId} />
      ) : null}

      {/* Stepper */}
      <ol className="mb-6 flex items-center">
        {steps.map((label, i) => (
          <li
            key={label}
            className={cn("flex items-center", i < last && "flex-1")}
          >
            <div className="flex items-center gap-2">
              <span
                className={cn(
                  "flex size-7 shrink-0 items-center justify-center rounded-full text-xs font-bold transition-colors",
                  i <= step
                    ? "bg-primary text-primary-foreground"
                    : "bg-muted text-muted-foreground",
                )}
              >
                {i < step ? <CheckIcon className="size-4" /> : i + 1}
              </span>
              <span
                className={cn(
                  "hidden text-sm font-medium sm:inline",
                  i === step ? "text-foreground" : "text-muted-foreground",
                )}
              >
                {label}
              </span>
            </div>
            {i < last ? (
              <span
                className={cn(
                  "mx-2 h-px flex-1 transition-colors",
                  i < step ? "bg-primary" : "bg-border",
                )}
              />
            ) : null}
          </li>
        ))}
      </ol>

      {/* Step content — all mounted, inactive ones hidden so FormData survives. */}
      <div ref={stepAreaRef} className="wizfade space-y-6">
        <div className={cn(step !== 0 && "hidden")}>
          <Section title={tp("sectionBasic")} subtitle={tp("sectionBasicSub")}>
            <Labeled label={t("jobTitle")} required>
              <input
                name="title"
                defaultValue={d?.title}
                placeholder={tp("titleHint")}
                list="pro-titles"
                autoComplete="off"
                onChange={(e) => {
                  if (titleError) setTitleError(false);
                  // Auto-pick the category from the title, unless one is
                  // already chosen (or restored from a draft).
                  const sel = categoryRef.current;
                  if (!sel || sel.value) return;
                  const slug = suggestCategorySlug(e.target.value);
                  const cat = slug
                    ? categories.find((c) => c.slug === slug)
                    : null;
                  if (cat) sel.value = cat.id;
                }}
                className={inputClass}
              />
              <datalist id="pro-titles">
                {PROFESSIONS.map((p) => (
                  <option key={p.label} value={p.label} />
                ))}
              </datalist>
            </Labeled>
            <div className="flex flex-wrap items-center gap-3">
              <button
                type="button"
                onClick={fillWithAi}
                disabled={aiPending}
                className="border-primary/40 bg-accent text-accent-foreground hover:border-primary inline-flex items-center gap-2 rounded-full border px-4 py-2 text-sm font-semibold transition-colors disabled:opacity-60"
              >
                <Sparkles
                  className={cn("size-4", aiPending && "animate-spin")}
                />
                {aiPending ? tp("aiGenerating") : tp("aiGenerate")}
              </button>
              {aiError ? (
                <span className="text-destructive text-sm">
                  {tp("aiError")}
                </span>
              ) : null}
            </div>
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
                ref={categoryRef}
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
        </div>

        <div className={cn("space-y-6", step !== 1 && "hidden")}>
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
        </div>

        <div className={cn(step !== 2 && "hidden")}>
          <Section
            title={tp("sectionLocation")}
            subtitle={tp("sectionLocationSub")}
          >
            <Labeled label={t("city")}>
              <input
                name="city"
                defaultValue={d?.city}
                onChange={(e) => setCityText(e.target.value)}
                className={inputClass}
              />
            </Labeled>
            <Labeled label={tp("address")}>
              <input
                name="addressText"
                defaultValue={d?.addressText}
                placeholder={tp("addressHint")}
                className={inputClass}
              />
            </Labeled>
            <input type="hidden" name="lat" value={pin?.lat ?? ""} readOnly />
            <input type="hidden" name="lng" value={pin?.lng ?? ""} readOnly />
            <div>
              <span className="text-foreground mb-1.5 block text-sm font-medium">
                {tp("locationMapHint")}
              </span>
              <LocationPicker
                lat={pin?.lat ?? null}
                lng={pin?.lng ?? null}
                onChange={setPin}
                cityHint={cityText || d?.city || null}
                locale={locale}
              />
            </div>
          </Section>
        </div>

        <div className={cn("space-y-6", step !== 3 && "hidden")}>
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
        </div>

        {step === last && preview ? (
          <JobPreview
            data={preview}
            title={tp("previewTitle")}
            sub={tp("previewSub")}
            empty={tp("noDescription")}
          />
        ) : null}
      </div>

      {titleError ? (
        <p className="text-destructive mt-3 text-sm">{tp("titleRequired")}</p>
      ) : null}
      {state.error ? (
        <p className="text-destructive mt-3 text-sm">{t("errUnknown")}</p>
      ) : null}

      {/* Footer nav */}
      <div className="border-border mt-6 flex items-center justify-between gap-3 border-t pt-4">
        <button
          type="button"
          onClick={() => setStep((s) => Math.max(s - 1, 0))}
          disabled={step === 0}
          className="border-border text-foreground hover:bg-muted h-11 rounded-lg border px-5 text-sm font-semibold transition-colors disabled:opacity-40"
        >
          ← {tp("back")}
        </button>
        <span className="text-muted-foreground text-sm">
          {tp("stepOf", { n: step + 1, total: steps.length })}
        </span>
        {step < last ? (
          <button
            type="button"
            onClick={goNext}
            className="bg-primary text-primary-foreground h-11 rounded-lg px-6 text-sm font-bold transition-opacity hover:opacity-90"
          >
            {tp("next")} →
          </button>
        ) : (
          <div className="flex gap-2">
            <button
              type="submit"
              name="status"
              value="draft"
              disabled={pending}
              className="border-border text-foreground hover:bg-muted h-11 rounded-lg border px-4 text-sm font-semibold transition-colors disabled:opacity-60"
            >
              {tp("saveDraft")}
            </button>
            <button
              type="submit"
              name="status"
              value="open"
              disabled={pending}
              className="bg-primary text-primary-foreground h-11 rounded-lg px-6 text-sm font-bold transition-opacity hover:opacity-90 disabled:opacity-60"
            >
              {t("publishJob")}
            </button>
          </div>
        )}
      </div>
    </form>
  );
}

/** Read-only "how it will look" preview, built from the current form values. */
function JobPreview({
  data,
  title,
  sub,
  empty,
}: {
  data: PreviewData;
  title: string;
  sub: string;
  empty: string;
}) {
  const blocks = [
    data.description,
    data.responsibilities,
    data.requirements,
    data.benefits,
  ].filter(Boolean);
  return (
    <div>
      <p className="text-primary font-mono text-xs font-semibold tracking-wider uppercase">
        {title}
      </p>
      <p className="text-muted-foreground mt-1 mb-4 text-sm">{sub}</p>

      <article className="border-border bg-card rounded-2xl border p-6">
        <h3 className="text-foreground text-xl font-bold">
          {data.title || "—"}
        </h3>
        {data.salary ? (
          <p className="text-foreground mt-1 font-mono text-sm font-semibold">
            {data.salary}
          </p>
        ) : null}

        {data.category ||
        data.location ||
        data.employment.length ||
        data.flags.length ? (
          <div className="mt-3 flex flex-wrap gap-2">
            {[data.category, data.location, ...data.employment, ...data.flags]
              .filter(Boolean)
              .map((chip, i) => (
                <span
                  key={i}
                  className="border-border bg-muted text-foreground rounded-full border px-3 py-1 text-xs font-medium"
                >
                  {chip}
                </span>
              ))}
          </div>
        ) : null}

        {blocks.length ? (
          <div className="mt-5 space-y-4">
            {blocks.map((b, i) => (
              <p
                key={i}
                className="text-foreground text-sm whitespace-pre-line"
              >
                {b}
              </p>
            ))}
          </div>
        ) : (
          <p className="text-muted-foreground mt-5 text-sm">{empty}</p>
        )}
      </article>
    </div>
  );
}
