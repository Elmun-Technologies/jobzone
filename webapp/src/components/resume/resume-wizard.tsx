"use client";

import {
  Check,
  Loader2,
  Plus,
  ShieldCheck,
  Sparkles,
  Trash2,
} from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { useEffect, useRef, useState, useTransition } from "react";

import { buttonVariants } from "@/components/ui/button";
import { SuggestInput } from "@/components/ui/suggest-input";
import { UzPhoneInput } from "@/components/ui/uz-phone-input";
// The plain router, not the locale-aware one from @/i18n/navigation: `next`
// arrives already locale-prefixed (quick-apply builds `/uz/jobs/<id>/apply`),
// and pushing that through the i18n router would prefix it twice. Same choice
// phone-otp-form makes for the same reason — so every path here is written
// out in full.
import { useRouter } from "next/navigation";
import { generateResumeSummary } from "@/lib/actions/ai-resume";
import { saveResume } from "@/lib/actions/resume";
import { registerDraftCapture } from "@/lib/draft-stash";
import { safeNext } from "@/lib/auth/safe-next";
import { suggestProfessions } from "@/lib/professions";
import { isCompleteUzPhone } from "@/lib/uz-phone";
import { districtsFor } from "@/lib/uz-districts";
import { UZ_REGIONS } from "@/lib/uz-regions";
// The client-safe half of the résumé module — `data/resume` itself is
// `server-only` (it holds the Supabase reads), and importing it from here
// pulls the server client into the browser bundle.
import {
  EMPTY_RESUME,
  type EducationEntry,
  type ExperienceEntry,
  type ResumeDraft,
} from "@/lib/data/resume-draft";
import { cn } from "@/lib/utils";

const inputClass =
  "border-border bg-card text-foreground focus:ring-primary focus:border-primary block w-full rounded-lg border px-3 py-2 text-sm outline-none transition-all focus:ring-1";

const STASH_KEY = "jz_resume_draft";
const STASH_STEP_KEY = "jz_resume_step";

const EMPTY_EDU: EducationEntry = {
  institution: "",
  degree: "",
  field: "",
  startYear: null,
  endYear: null,
};

const EMPTY_EXP: ExperienceEntry = {
  title: "",
  companyName: "",
  description: "",
  startYear: null,
  startMonth: null,
  endYear: null,
  endMonth: null,
  current: false,
};

function reviveDraft(d: Record<string, unknown>): ResumeDraft {
  const certs = Array.isArray(d.certificates) ? d.certificates : [];
  return {
    ...EMPTY_RESUME,
    ...(d as Partial<ResumeDraft>),
    certificates: certs.map((c: unknown) => {
      const cert = (c ?? {}) as Record<string, unknown>;
      const issueDate = cert.issueDate;
      return {
        name: typeof cert.name === "string" ? cert.name : "",
        organization: typeof cert.organization === "string" ? cert.organization : "",
        issueDate: typeof issueDate === "string" ? new Date(issueDate) : issueDate instanceof Date ? issueDate : null,
      };
    }),
  };
}

function YearSelect({
  value,
  onChange,
  label,
  className,
}: {
  value: number | null;
  onChange: (v: number | null) => void;
  label: string;
  className?: string;
}) {
  const current = new Date().getFullYear();
  const years = Array.from({ length: 60 }, (_, i) => current - i);
  return (
    <div className={className}>
      <label className="text-muted-foreground mb-1 block text-xs font-medium">
        {label}
      </label>
      <select
        value={value ?? ""}
        onChange={(e) => onChange(e.target.value ? Number(e.target.value) : null)}
        className={inputClass}
      >
        <option value="">—</option>
        {years.map((y) => (
          <option key={y} value={y}>
            {y}
          </option>
        ))}
      </select>
    </div>
  );
}

export function ResumeWizard({
  initial,
  next: nextParam,
}: {
  initial: ResumeDraft;
  /** Where to send the seeker once the résumé is saved — the job they were
   * applying to when quick-apply found they had no résumé. Locale-prefixed
   * and sanitized through safeNext before use. */
  next?: string;
}) {
  const t = useTranslations("resume");
  const router = useRouter();
  const [step, setStep] = useState(0);
  const [draft, setDraft] = useState<ResumeDraft>(initial);
  // The draft-capture callback is registered once, so it would close over the
  // first render's values. These mirrors give it what is on screen right now,
  // written in an effect rather than during render (refs are not render state).
  const draftRef = useRef(draft);
  const stepRef = useRef(step);
  useEffect(() => {
    draftRef.current = draft;
    stepRef.current = step;
  }, [draft, step]);
  const [error, setError] = useState(false);
  const [pending, start] = useTransition();
  const locale = useLocale();

  // Auth-last: if the guest signed in at save-time and came back, restore the
  // résumé they were filling (stashed below) and jump to the final step so a
  // single tap finishes the save. No work is lost to the sign-in detour.
  useEffect(() => {
    const saved = sessionStorage.getItem(STASH_KEY);
    if (!saved) return;
    const savedStep = sessionStorage.getItem(STASH_STEP_KEY);
    sessionStorage.removeItem(STASH_KEY);
    sessionStorage.removeItem(STASH_STEP_KEY);
    // Restoring client-only storage after mount is intentional here (a lazy
    // initializer would desync SSR hydration).
    try {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setDraft(reviveDraft(JSON.parse(saved)));
      // A parked step means the wizard was interrupted mid-flow (a language
      // switch) — put them back where they were. Without one this is the
      // sign-in detour, which happens at save-time and returns to the end.
      const parsed = savedStep === null ? NaN : Number(savedStep);
      setStep(
        Number.isInteger(parsed) && parsed >= 0 && parsed <= 3 ? parsed : 3,
      );
    } catch {
      // Ignore a malformed stash.
    }
  }, []);

  // Changing language rebuilds the wizard; park the draft and the step so the
  // remount picks both back up through the effect above.
  useEffect(
    () =>
      registerDraftCapture(() => {
        sessionStorage.setItem(STASH_KEY, JSON.stringify(draftRef.current));
        sessionStorage.setItem(STASH_STEP_KEY, String(stepRef.current));
      }),
    [],
  );

  const set = <K extends keyof ResumeDraft>(key: K, value: ResumeDraft[K]) =>
    setDraft((d) => ({ ...d, [key]: value }));

  const [aiPending, setAiPending] = useState(false);
  const [aiFellBack, setAiFellBack] = useState(false);

  // "Write with AI": turn the seeker's role + experience + a few notes into a
  // professional summary. Never blocks — GLM off/erroring returns a localized
  // starter (fellBack) the seeker edits. Overwrites the summary field (that's
  // the point); anything else typed stays.
  async function writeSummaryWithAi() {
    if (aiPending) return;
    setAiPending(true);
    setAiFellBack(false);
    try {
      const res = await generateResumeSummary({
        // The AI writes about one role — the first title is the headline.
        position: draft.positions[0] ?? "",
        experienceLevel: draft.experienceLevel || null,
        city: draft.city || null,
        notes: draft.summary || null,
        locale,
      });
      // Mark it as the untouched AI draft; a manual edit (below) clears this.
      setDraft((d) => ({
        ...d,
        summary: res.summary,
        summaryAiGenerated: true,
      }));
      if (res.source === "template" && res.fellBack) setAiFellBack(true);
    } finally {
      setAiPending(false);
    }
  }

  const setLang = (code: string, level: string) =>
    setDraft((d) => ({ ...d, languages: { ...d.languages, [code]: level } }));

  const addEdu = () =>
    setDraft((d) => ({
      ...d,
      educations: [...d.educations, { ...EMPTY_EDU }],
    }));
  const removeEdu = (i: number) =>
    setDraft((d) => ({
      ...d,
      educations: d.educations.filter((_, j) => j !== i),
    }));
  const setEdu = <K extends keyof EducationEntry>(
    i: number,
    key: K,
    value: EducationEntry[K],
  ) =>
    setDraft((d) => ({
      ...d,
      educations: d.educations.map((e, j) =>
        j === i ? { ...e, [key]: value } : e,
      ),
    }));

  const addExp = () =>
    setDraft((d) => ({
      ...d,
      experiences: [...d.experiences, { ...EMPTY_EXP }],
    }));
  const removeExp = (i: number) =>
    setDraft((d) => ({
      ...d,
      experiences: d.experiences.filter((_, j) => j !== i),
    }));
  const setExp = <K extends keyof ExperienceEntry>(
    i: number,
    key: K,
    value: ExperienceEntry[K],
  ) =>
    setDraft((d) => ({
      ...d,
      experiences: d.experiences.map((e, j) =>
        j === i ? { ...e, [key]: value } : e,
      ),
    }));

  const steps = [
    t("stepPersonal"),
    t("stepExperience"),
    t("stepEducation"),
    t("stepContacts"),
  ];

  const valid =
    step === 0
      ? draft.positions.length > 0 && draft.fullName.trim() !== ""
      : step === 1
        ? draft.experienceLevel !== ""
        : step === 3
          ? isCompleteUzPhone(draft.phone)
          : true;

  function next() {
    if (!valid) return;
    if (step < steps.length - 1) {
      setStep((s) => s + 1);
      return;
    }
    setError(false);
    start(async () => {
      const res = await saveResume(draft);
      if (res.signedOut) {
        // Auth-last: park the draft and sign in, returning here to finish.
        // `next` rides along on the return URL, so the job the seeker was
        // applying to survives the sign-in detour too, not just the draft.
        sessionStorage.setItem(STASH_KEY, JSON.stringify(draft));
        const back =
          `/${locale}/resumes/new` +
          (nextParam ? `?next=${encodeURIComponent(nextParam)}` : "");
        router.push(`/${locale}/sign-in?next=${encodeURIComponent(back)}`);
      } else if (res.error) setError(true);
      // Back to the job they were applying to, if they came from one;
      // otherwise the jobs matched to the résumé they just saved. `saved=1`
      // is what makes that landing say the résumé went through — without it
      // four steps of typing ended on a jobs list with no acknowledgement at
      // all, and no way to tell a save from a silent failure.
      else {
        router.push(
          safeNext(nextParam, `/${locale}/account/recommended?saved=1`),
        );
      }
    });
  }

  return (
    <div className="mx-auto max-w-2xl">
      <h1 className="text-foreground text-center text-2xl font-bold sm:text-3xl">
        {t("title")}
      </h1>
      <p className="text-muted-foreground mt-2 text-center text-sm">
        {t("subtitle")}
      </p>

      {/* Progress */}
      <div className="mt-8 flex items-center justify-between px-2">
        {steps.map((s, i) => (
          <div key={s} className="flex flex-1 items-center last:flex-none">
            <div
              className={cn(
                "flex size-8 shrink-0 items-center justify-center rounded-full text-sm font-bold transition-colors",
                i <= step
                  ? "bg-primary text-primary-foreground"
                  : "bg-muted text-muted-foreground",
              )}
            >
              {i < step ? <Check className="size-4" /> : i + 1}
            </div>
            {i < steps.length - 1 && (
              <div
                className={cn(
                  "mx-2 h-0.5 flex-1 transition-colors",
                  i < step ? "bg-primary" : "bg-muted",
                )}
              />
            )}
          </div>
        ))}
      </div>

      <div className="mt-8">
        {step === 0 && (
          <div className="rise-in space-y-6">
            <div>
              <label className="text-foreground mb-1.5 block text-sm font-semibold">
                {t("fullName")}
              </label>
              <input
                type="text"
                value={draft.fullName}
                onChange={(e) => set("fullName", e.target.value)}
                placeholder={t("fullNameHint")}
                className={inputClass}
              />
            </div>

            <div>
              <label className="text-foreground mb-1.5 block text-sm font-semibold">
                {t("desiredPosition")}
              </label>
              <SuggestInput
                value={draft.positions[0] || ""}
                onValueChange={(v) => set("positions", v ? [v] : [])}
                placeholder={t("desiredPositionHint")}
                suggest={suggestProfessions}
                className={inputClass}
              />
            </div>

            <div>
              <label className="text-foreground mb-1.5 block text-sm font-semibold">
                {t("summary")}
              </label>
              <div className="relative">
                <textarea
                  value={draft.summary}
                  onChange={(e) => {
                    set("summary", e.target.value);
                    if (draft.summaryAiGenerated) {
                      set("summaryAiGenerated", false);
                    }
                  }}
                  placeholder={t("summaryHint")}
                  rows={4}
                  className={cn(inputClass, "pr-10")}
                />
                <button
                  type="button"
                  onClick={writeSummaryWithAi}
                  disabled={aiPending || draft.positions.length === 0}
                  className={cn(
                    "absolute right-2 top-2 rounded-lg p-1.5 transition-colors",
                    aiPending
                      ? "bg-muted text-muted-foreground"
                      : "text-primary hover:bg-primary/10",
                  )}
                  title={t("aiWrite")}
                >
                  {aiPending ? (
                    <Loader2 className="size-4 animate-spin" />
                  ) : (
                    <Sparkles className="size-4" />
                  )}
                </button>
              </div>
              {aiFellBack && (
                <p className="text-muted-foreground mt-1.5 text-xs">
                  {t("aiFellBack")}
                </p>
              )}
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-foreground mb-1.5 block text-sm font-semibold">
                  {t("region")}
                </label>
                <select
                  value={draft.region || ""}
                  onChange={(e) => {
                    set("region", e.target.value || null);
                    set("city", null);
                  }}
                  className={inputClass}
                >
                  <option value="">—</option>
                  {UZ_REGIONS.map((r) => (
                    <option key={r} value={r}>
                      {r}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="text-foreground mb-1.5 block text-sm font-semibold">
                  {t("city")}
                </label>
                <select
                  value={draft.city || ""}
                  onChange={(e) => set("city", e.target.value || null)}
                  disabled={!draft.region}
                  className={inputClass}
                >
                  <option value="">—</option>
                  {draft.region &&
                    districtsFor(draft.region).map((d) => (
                      <option key={d} value={d}>
                        {d}
                      </option>
                    ))}
                </select>
              </div>
            </div>
          </div>
        )}

        {step === 1 && (
          <div className="rise-in space-y-8">
            <div>
              <label className="text-foreground mb-1.5 block text-sm font-semibold">
                {t("experienceLevel")}
              </label>
              <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
                {[
                  { v: "entry", l: t("expEntry") },
                  { v: "junior", l: t("expJunior") },
                  { v: "mid", l: t("expMid") },
                  { v: "senior", l: t("expSenior") },
                  { v: "lead", l: t("expLead") },
                ].map((l) => (
                  <button
                    key={l.v}
                    type="button"
                    onClick={() => set("experienceLevel", l.v)}
                    className={cn(
                      "rounded-xl border px-3 py-2 text-sm font-medium transition-all",
                      draft.experienceLevel === l.v
                        ? "border-primary bg-primary/5 text-primary"
                        : "border-border bg-card text-muted-foreground hover:bg-muted",
                    )}
                  >
                    {l.l}
                  </button>
                ))}
              </div>
            </div>

            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h2 className="text-foreground text-sm font-semibold">
                  {t("workHistory")}
                </h2>
                <button
                  type="button"
                  onClick={addExp}
                  className="text-primary flex items-center gap-1 text-xs font-bold hover:underline"
                >
                  <Plus className="size-3" />
                  {t("addExperience")}
                </button>
              </div>

              {draft.experiences.map((exp, i) => (
                <div
                  key={i}
                  className="border-border bg-card relative space-y-4 rounded-2xl border p-4"
                >
                  <button
                    type="button"
                    onClick={() => removeExp(i)}
                    className="text-muted-foreground hover:text-destructive absolute right-2 top-2 p-1 transition-colors"
                  >
                    <Trash2 className="size-4" />
                  </button>
                  <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                    <div>
                      <label className="text-muted-foreground mb-1 block text-xs font-medium">
                        {t("jobTitle")}
                      </label>
                      <SuggestInput
                        value={exp.title}
                        onValueChange={(v) => setExp(i, "title", v)}
                        placeholder={t("jobTitleHint")}
                        suggest={suggestProfessions}
                        className={inputClass}
                      />
                    </div>
                    <div>
                      <label className="text-muted-foreground mb-1 block text-xs font-medium">
                        {t("company")}
                      </label>
                      <input
                        type="text"
                        value={exp.companyName}
                        onChange={(e) => setExp(i, "companyName", e.target.value)}
                        placeholder={t("companyHint")}
                        className={inputClass}
                      />
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
                    <YearSelect
                      label={t("startYear")}
                      value={exp.startYear}
                      onChange={(v) => setExp(i, "startYear", v)}
                    />
                    <div className="opacity-0 sm:block" />
                    {!exp.current && (
                      <YearSelect
                        label={t("endYear")}
                        value={exp.endYear}
                        onChange={(v) => setExp(i, "endYear", v)}
                      />
                    )}
                  </div>
                  <div className="flex items-center gap-2">
                    <input
                      type="checkbox"
                      id={`exp-current-${i}`}
                      checked={exp.current}
                      onChange={(e) => setExp(i, "current", e.target.checked)}
                      className="text-primary focus:ring-primary size-4 rounded border-gray-300"
                    />
                    <label
                      htmlFor={`exp-current-${i}`}
                      className="text-muted-foreground text-xs font-medium"
                    >
                      {t("currentlyWorkHere")}
                    </label>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {step === 2 && (
          <div className="rise-in space-y-8">
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h2 className="text-foreground text-sm font-semibold">
                  {t("education")}
                </h2>
                <button
                  type="button"
                  onClick={addEdu}
                  className="text-primary flex items-center gap-1 text-xs font-bold hover:underline"
                >
                  <Plus className="size-3" />
                  {t("addEducation")}
                </button>
              </div>

              {draft.educations.map((edu, i) => (
                <div
                  key={i}
                  className="border-border bg-card relative space-y-4 rounded-2xl border p-4"
                >
                  <button
                    type="button"
                    onClick={() => removeEdu(i)}
                    className="text-muted-foreground hover:text-destructive absolute right-2 top-2 p-1 transition-colors"
                  >
                    <Trash2 className="size-4" />
                  </button>
                  <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                    <div>
                      <label className="text-muted-foreground mb-1 block text-xs font-medium">
                        {t("institution")}
                      </label>
                      <input
                        type="text"
                        value={edu.institution}
                        onChange={(e) => setEdu(i, "institution", e.target.value)}
                        placeholder={t("institutionHint")}
                        className={inputClass}
                      />
                    </div>
                    <div>
                      <label className="text-muted-foreground mb-1 block text-xs font-medium">
                        {t("degree")}
                      </label>
                      <input
                        type="text"
                        value={edu.degree}
                        onChange={(e) => setEdu(i, "degree", e.target.value)}
                        placeholder={t("degreeHint")}
                        className={inputClass}
                      />
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <YearSelect
                      label={t("startYear")}
                      value={edu.startYear}
                      onChange={(v) => setEdu(i, "startYear", v)}
                    />
                    <YearSelect
                      label={t("endYear")}
                      value={edu.endYear}
                      onChange={(v) => setEdu(i, "endYear", v)}
                    />
                  </div>
                </div>
              ))}
            </div>

            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h2 className="text-foreground text-sm font-semibold">
                  {t("languages")}
                </h2>
              </div>
              <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                {[
                  { c: "uz", n: "O'zbek tili" },
                  { c: "ru", n: "Rus tili" },
                  { c: "en", n: "Ingliz tili" },
                ].map((l) => (
                  <div
                    key={l.c}
                    className="border-border bg-card flex items-center justify-between rounded-xl border p-3"
                  >
                    <span className="text-foreground text-sm font-medium">
                      {l.n}
                    </span>
                    <select
                      value={draft.languages[l.c] ?? ""}
                      onChange={(e) => setLang(l.c, e.target.value)}
                      className="bg-accent text-foreground rounded-lg border-none px-2 py-1 text-xs outline-none"
                    >
                      <option value="">—</option>
                      <option value="a1_a2">A1 / A2</option>
                      <option value="b1_b2">B1 / B2</option>
                      <option value="c1_c2">C1 / C2</option>
                      <option value="native">Native</option>
                    </select>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {step === 3 && (
          <div className="rise-in space-y-6">
            <div>
              <label className="text-foreground mb-1.5 block text-sm font-semibold">
                {t("phone")}
              </label>
              <UzPhoneInput
                value={draft.phone}
                onChange={(v) => set("phone", v)}
                className={inputClass}
              />
              <p className="text-muted-foreground mt-2 flex items-center gap-1.5 text-xs">
                <ShieldCheck className="size-3.5 shrink-0" />
                {t("phonePrivacy")}
              </p>
            </div>

            <div className="bg-primary/5 border-primary/20 rounded-2xl border p-4">
              <h3 className="text-primary text-sm font-bold">
                {t("readyToSave")}
              </h3>
              <p className="text-muted-foreground mt-1 text-xs">
                {t("saveNotice")}
              </p>
            </div>

            {error && (
              <div className="bg-destructive/10 text-destructive rounded-xl p-3 text-sm font-medium">
                {t("saveError")}
              </div>
            )}
          </div>
        )}
      </div>

      {/* Actions */}
      <div className="mt-10 flex items-center justify-between gap-4">
        <button
          type="button"
          onClick={() => (step > 0 ? setStep((s) => s - 1) : router.back())}
          className={cn(
            buttonVariants({ variant: "outline", size: "md" }),
            "flex-1",
          )}
        >
          {step === 0 ? t("cancel") : t("back")}
        </button>
        <button
          type="button"
          onClick={next}
          disabled={!valid || pending}
          className={cn(
            buttonVariants({ variant: "primary", size: "md" }),
            "flex-1",
          )}
        >
          {pending ? (
            <Loader2 className="size-4 animate-spin" />
          ) : step === steps.length - 1 ? (
            t("finish")
          ) : (
            t("next")
          )}
        </button>
      </div>
    </div>
  );
}
