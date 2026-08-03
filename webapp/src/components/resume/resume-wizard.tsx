"use client";

import {
  Check,
  Loader2,
  Plus,
  ShieldCheck,
  Sparkles,
  Trash2,
  X,
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
  type CertificateEntry,
  type EducationEntry,
  type ExperienceEntry,
  type ResumeDraft,
} from "@/lib/data/resume-draft";
import { cn } from "@/lib/utils";

const inputClass =
  "border-border bg-background text-foreground placeholder:text-muted-foreground focus-visible:ring-ring h-11 w-full rounded-lg border px-3 text-sm focus-visible:ring-2 focus-visible:outline-none";

const EXP = ["none", "under_1", "1_3", "3_5", "5_plus"] as const;
const MARITAL = ["single", "married", "divorced"] as const;
const LANGS = ["ru", "en", "tr", "tg", "uz"] as const;
const LEVELS = ["none", "a1_a2", "b1_b2", "c1_c2", "native"] as const;

// Where an in-progress résumé is parked while a guest signs in at save-time.
const STASH_KEY = "yolla-resume-draft";
// …and which step they were on, written only when the wizard is parked
// mid-flow (a language switch). The sign-in detour happens at save-time and
// deliberately returns to the last step, so it leaves this unset.
const STASH_STEP_KEY = "yolla-resume-draft-step";

const EMPTY_EDU: EducationEntry = {
  school: "",
  degree: "",
  field: "",
  startYear: "",
  endYear: "",
  isCurrent: false,
};

const EMPTY_EXP: ExperienceEntry = {
  title: "",
  companyName: "",
  startYear: "",
  endYear: "",
  isCurrent: false,
  description: "",
};

const EMPTY_CERT: CertificateEntry = {
  name: "",
  issuer: "",
  issuedYear: "",
  expiryYear: "",
};

function Field({
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

function ChipGroup({
  options,
  value,
  onChange,
}: {
  options: { value: string; label: string }[];
  value: string;
  onChange: (v: string) => void;
}) {
  return (
    <div className="flex flex-wrap gap-2">
      {options.map((o) => {
        const on = value === o.value;
        return (
          <button
            key={o.value}
            type="button"
            aria-pressed={on}
            onClick={() => onChange(o.value)}
            className={cn(
              "rounded-full border px-4 py-2 text-sm font-medium transition-colors",
              on
                ? "border-primary bg-primary text-primary-foreground"
                : "border-border bg-background text-foreground hover:border-primary/40",
            )}
          >
            {o.label}
          </button>
        );
      })}
    </div>
  );
}

/** Groups a digit string for display: "15000000" -> "15 000 000". */
const groupDigits = (s: string) => s.replace(/\B(?=(\d{3})+(?!\d))/g, " ");

/** How many job titles one résumé may carry (mirrors the 0082 constraint). */
const MAX_POSITIONS = 3;

/**
 * The résumé's desired job titles, as removable chips over a suggestion field.
 *
 * A blue-collar seeker is rarely one title: the same person is "Sotuvchi",
 * "Kassir" and "Sotuvchi-konsultant", and with a single headline they matched
 * only the vacancies that happened to use their one word. Three is the cap —
 * enough to cover a trade, few enough that the list still means something.
 */
function PositionsField({
  values,
  onChange,
  placeholder,
  removeLabel,
}: {
  values: string[];
  onChange: (next: string[]) => void;
  placeholder: string;
  removeLabel: string;
}) {
  const [text, setText] = useState("");
  const full = values.length >= MAX_POSITIONS;

  function add(raw: string) {
    const value = raw.trim();
    if (!value || full) return;
    // Case-insensitive de-dupe: "Sotuvchi" and "sotuvchi" are one title.
    if (values.some((v) => v.toLowerCase() === value.toLowerCase())) {
      setText("");
      return;
    }
    onChange([...values, value]);
    setText("");
  }

  return (
    <div>
      {values.length > 0 ? (
        <ul className="mb-2 flex flex-wrap gap-2">
          {values.map((v) => (
            <li key={v}>
              <span className="border-primary/40 bg-accent text-accent-foreground inline-flex items-center gap-1.5 rounded-full border py-1.5 pr-2 pl-3 text-sm font-medium">
                {v}
                <button
                  type="button"
                  onClick={() => onChange(values.filter((x) => x !== v))}
                  aria-label={`${removeLabel}: ${v}`}
                  className="text-muted-foreground hover:text-destructive"
                >
                  <X className="size-4" />
                </button>
              </span>
            </li>
          ))}
        </ul>
      ) : null}
      {!full ? (
        <SuggestInput
          className={inputClass}
          placeholder={placeholder}
          value={text}
          onValueChange={setText}
          // Picking from the list is the choice — no extra "add" tap after it.
          // Enter commits a title we don't list; blur keeps the text so a
          // half-typed trade isn't thrown away by tapping elsewhere.
          onPick={add}
          onSubmitValue={add}
          onBlur={add}
          suggest={suggestProfessions}
        />
      ) : null}
    </div>
  );
}

/**
 * Restores a stashed draft written by an older build.
 *
 * A guest who was filling the wizard when the deploy landed comes back from
 * sign-in with `{ position: "Sotuvchi", city: "Toshkent" }` in sessionStorage —
 * the pre-0082 shape. Without this the wizard would remount straight onto
 * `draft.positions.length` and blank-screen them at the exact moment they
 * finally signed in, which is the one moment auth-last cannot afford to lose.
 */
function reviveDraft(raw: unknown): ResumeDraft {
  const d = (raw ?? {}) as Partial<ResumeDraft> & { position?: unknown };
  const positions = Array.isArray(d.positions)
    ? d.positions.filter(
        (p): p is string => typeof p === "string" && !!p.trim(),
      )
    : typeof d.position === "string" && d.position.trim() !== ""
      ? [d.position.trim()]
      : [];
  return {
    ...EMPTY_RESUME,
    ...d,
    positions,
    region: typeof d.region === "string" ? d.region : "",
    district: typeof d.district === "string" ? d.district : "",
  };
}

/**
 * Year picker for the history sections (worked / studied / certified from–to).
 *
 * These were free numeric inputs, which accept "20026" and "1899" as happily
 * as a real year — and the value is stored as a date (`YYYY-01-01`), so a typo
 * lands in the database and then sorts the seeker's own history wrongly. The
 * range runs from this year back 60, newest first: nearly every entry a seeker
 * adds is recent, and the one they want should be at the top of the list.
 */
function YearSelect({
  value,
  onChange,
  label,
  disabled,
  future = 0,
}: {
  value: string;
  onChange: (v: string) => void;
  label: string;
  disabled?: boolean;
  /** Years ahead of today to offer (a certificate's expiry is in the future). */
  future?: number;
}) {
  const thisYear = new Date().getFullYear();
  const years = Array.from({ length: 61 + future }, (_, i) =>
    String(thisYear + future - i),
  );
  return (
    <select
      className={inputClass}
      value={disabled ? "" : value}
      disabled={disabled}
      aria-label={label}
      onChange={(e) => onChange(e.target.value)}
    >
      <option value="">{label}</option>
      {years.map((y) => (
        <option key={y} value={y}>
          {y}
        </option>
      ))}
    </select>
  );
}

/** Day / month / year dropdowns for a birth date — far clearer than the native
 * date picker's endless year scroll. Value + onChange are "YYYY-MM-DD" (or ""
 * while incomplete). Month names are localized via Intl (no extra strings). */
function BirthDatePicker({
  value,
  onChange,
  locale,
  labels,
}: {
  value: string;
  onChange: (v: string) => void;
  locale: string;
  labels: { day: string; month: string; year: string };
}) {
  const [yy = "", mm = "", dd = ""] = value ? value.split("-") : [];
  const thisYear = new Date().getFullYear();
  const years = Array.from({ length: 66 }, (_, i) => String(thisYear - 14 - i));
  const months = Array.from({ length: 12 }, (_, i) => ({
    value: String(i + 1).padStart(2, "0"),
    label: new Intl.DateTimeFormat(locale, { month: "long" }).format(
      new Date(2000, i, 1),
    ),
  }));
  const days = Array.from({ length: 31 }, (_, i) =>
    String(i + 1).padStart(2, "0"),
  );
  const emit = (y: string, m: string, d: string) =>
    onChange(y && m && d ? `${y}-${m}-${d}` : "");
  const cls = cn(inputClass, "bg-background");
  return (
    <div className="grid grid-cols-3 gap-2">
      <select
        className={cls}
        value={dd}
        onChange={(e) => emit(yy, mm, e.target.value)}
      >
        <option value="">{labels.day}</option>
        {days.map((d) => (
          <option key={d} value={d}>
            {Number(d)}
          </option>
        ))}
      </select>
      <select
        className={cls}
        value={mm}
        onChange={(e) => emit(yy, e.target.value, dd)}
      >
        <option value="">{labels.month}</option>
        {months.map((m) => (
          <option key={m.value} value={m.value}>
            {m.label}
          </option>
        ))}
      </select>
      <select
        className={cls}
        value={yy}
        onChange={(e) => emit(e.target.value, mm, dd)}
      >
        <option value="">{labels.year}</option>
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

  const addCert = () =>
    setDraft((d) => ({
      ...d,
      certificates: [...d.certificates, { ...EMPTY_CERT }],
    }));
  const removeCert = (i: number) =>
    setDraft((d) => ({
      ...d,
      certificates: d.certificates.filter((_, j) => j !== i),
    }));
  const setCert = <K extends keyof CertificateEntry>(
    i: number,
    key: K,
    value: CertificateEntry[K],
  ) =>
    setDraft((d) => ({
      ...d,
      certificates: d.certificates.map((c, j) =>
        j === i ? { ...c, [key]: value } : c,
      ),
    }));

  // Custom languages: add any language beyond the fixed set (stored by name).
  const [newLang, setNewLang] = useState("");
  const addLang = () => {
    const name = newLang.trim();
    if (!name) return;
    setDraft((d) => ({
      ...d,
      languages: { ...d.languages, [name]: d.languages[name] ?? "a1_a2" },
    }));
    setNewLang("");
  };
  const removeLang = (code: string) =>
    setDraft((d) => {
      const next = { ...d.languages };
      delete next[code];
      return { ...d, languages: next };
    });

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

      {/* Stepper */}
      <ol className="mt-8 flex items-center justify-center gap-2">
        {steps.map((label, i) => (
          <li key={label} className="flex items-center gap-2">
            <span
              className={cn(
                "flex size-8 items-center justify-center rounded-full text-sm font-bold",
                i < step
                  ? "bg-primary text-primary-foreground"
                  : i === step
                    ? "border-primary text-primary border-2"
                    : "border-border text-muted-foreground border",
              )}
            >
              {i < step ? <Check className="size-4" /> : i + 1}
            </span>
            <span
              className={cn(
                "hidden text-sm font-medium sm:inline",
                i === step ? "text-foreground" : "text-muted-foreground",
              )}
            >
              {label}
            </span>
            {/* The connector fills in behind you, so progress reads at a
                glance on a phone, where the step labels are hidden. */}
            {i < steps.length - 1 ? (
              <span
                className={cn(
                  "mx-1 h-px w-6 transition-colors",
                  i < step ? "bg-primary" : "bg-border",
                )}
              />
            ) : null}
          </li>
        ))}
      </ol>

      <div className="border-border bg-card mt-8 space-y-5 rounded-2xl border p-6">
        {step === 0 ? (
          <>
            <Field label={t("position")} required>
              {/* Type-and-pick over the curated blue-collar list: the seekers
                  this product is built for name their trade a dozen different
                  ways ("prodavets", "sotuvchi konsultant"), and a title that
                  matches the postings is what makes the two-way résumé match
                  fire. Free text still wins if their trade isn't listed. */}
              <PositionsField
                values={draft.positions}
                onChange={(v) => set("positions", v)}
                placeholder={t("positionHint")}
                removeLabel={t("remove")}
              />
              <p className="text-muted-foreground mt-1.5 text-xs">
                {t("positionsHelp", { max: MAX_POSITIONS })}
              </p>
            </Field>
            <Field label={t("fullName")} required>
              <input
                className={inputClass}
                value={draft.fullName}
                onChange={(e) => set("fullName", e.target.value)}
              />
              {/* Uzbek passports are in Latin script; an employer comparing a
                  Cyrillic résumé name against a passport at the door is a real
                  first-day problem, so ask for it the way the document has it. */}
              <p className="text-muted-foreground mt-1.5 text-xs">
                {t("fullNameHelp")}
              </p>
            </Field>
            <div className="grid gap-5 sm:grid-cols-2">
              <Field label={t("birthDate")}>
                <BirthDatePicker
                  value={draft.birthDate}
                  onChange={(v) => set("birthDate", v)}
                  locale={locale}
                  labels={{
                    day: t("dobDay"),
                    month: t("dobMonth"),
                    year: t("dobYear"),
                  }}
                />
              </Field>
              <Field label={t("gender")}>
                <ChipGroup
                  value={draft.gender}
                  onChange={(v) => set("gender", v)}
                  options={[
                    { value: "male", label: t("male") },
                    { value: "female", label: t("female") },
                  ]}
                />
              </Field>
            </div>
            {/* Where they want to work, from the same viloyat/tuman list the
                employer form writes into jobs.region/district — typed city
                names ("Ташкент" vs "Toshkent" vs "toshkent sh.") compared
                equal to nothing, which is most of why location matching used
                to miss. District is optional: plenty of seekers will take the
                whole region. */}
            <div className="grid gap-5 sm:grid-cols-2">
              <Field label={t("region")}>
                <select
                  className={inputClass}
                  value={draft.region}
                  onChange={(e) =>
                    // A new region invalidates the district under it.
                    setDraft((d) => ({
                      ...d,
                      region: e.target.value,
                      district: "",
                    }))
                  }
                >
                  <option value="">{t("regionAny")}</option>
                  {UZ_REGIONS.map((r) => (
                    <option key={r} value={r}>
                      {r}
                    </option>
                  ))}
                </select>
              </Field>
              <Field label={t("district")}>
                <select
                  className={inputClass}
                  value={draft.district}
                  disabled={!draft.region}
                  onChange={(e) => set("district", e.target.value)}
                >
                  <option value="">{t("districtAny")}</option>
                  {districtsFor(draft.region).map((d) => (
                    <option key={d} value={d}>
                      {d}
                    </option>
                  ))}
                </select>
              </Field>
            </div>
            <Field label={t("maritalStatus")}>
              <ChipGroup
                value={draft.maritalStatus}
                onChange={(v) => set("maritalStatus", v)}
                options={MARITAL.map((m) => ({ value: m, label: t(m) }))}
              />
            </Field>
          </>
        ) : null}

        {step === 1 ? (
          <>
            <Field label={t("experience")} required>
              <ChipGroup
                value={draft.experienceLevel}
                onChange={(v) => set("experienceLevel", v)}
                options={EXP.map((e) => ({ value: e, label: t(`exp.${e}`) }))}
              />
            </Field>

            {/* Real work history — one card per job (experiences table). */}
            <div>
              <p className="text-foreground text-sm font-medium">
                {t("workHistory")}
              </p>
              {/* Why it's worth the typing: a past job title is a matching
                  signal in its own right (recommended_jobs scores it), so this
                  is a promise the product actually keeps, not a nag. */}
              <p className="text-muted-foreground mt-0.5 mb-2 text-xs">
                {t("workHistoryNudge")}
              </p>
              {draft.experiences.map((exp, i) => (
                <div
                  key={i}
                  className="border-border mb-3 rounded-xl border p-4"
                >
                  <div className="mb-3 flex items-center justify-between">
                    <span className="text-foreground text-sm font-semibold">
                      {t("jobLabel")} #{i + 1}
                    </span>
                    <button
                      type="button"
                      onClick={() => removeExp(i)}
                      aria-label={t("remove")}
                      className="text-muted-foreground hover:text-destructive"
                    >
                      <Trash2 className="size-4" />
                    </button>
                  </div>
                  <div className="space-y-3">
                    <input
                      className={inputClass}
                      placeholder={t("jobPosition")}
                      value={exp.title}
                      onChange={(e) => setExp(i, "title", e.target.value)}
                    />
                    <input
                      className={inputClass}
                      placeholder={t("company")}
                      value={exp.companyName}
                      onChange={(e) => setExp(i, "companyName", e.target.value)}
                    />
                    <div className="grid gap-3 sm:grid-cols-2">
                      <YearSelect
                        label={t("startYear")}
                        value={exp.startYear}
                        onChange={(v) => setExp(i, "startYear", v)}
                      />
                      <YearSelect
                        label={t("endYear")}
                        value={exp.endYear}
                        disabled={exp.isCurrent}
                        onChange={(v) => setExp(i, "endYear", v)}
                      />
                    </div>
                    <label className="text-foreground flex items-center gap-2 text-sm">
                      <input
                        type="checkbox"
                        checked={exp.isCurrent}
                        onChange={(e) =>
                          setExp(i, "isCurrent", e.target.checked)
                        }
                      />
                      {t("currentlyWorking")}
                    </label>
                    <textarea
                      className={cn(inputClass, "h-auto min-h-[4rem] py-2.5")}
                      placeholder={t("jobDutiesHint")}
                      value={exp.description}
                      onChange={(e) => setExp(i, "description", e.target.value)}
                    />
                  </div>
                </div>
              ))}
              <button
                type="button"
                onClick={addExp}
                className="border-border text-foreground hover:border-primary/40 inline-flex items-center gap-2 rounded-lg border border-dashed px-4 py-2 text-sm font-medium"
              >
                <Plus className="size-4" /> {t("addJob")}
              </button>
            </div>

            <Field label={t("expectedSalary")}>
              <div className="flex gap-2">
                <input
                  type="text"
                  inputMode="numeric"
                  className={inputClass}
                  placeholder={t("salaryHint")}
                  value={
                    draft.expectedSalary
                      ? groupDigits(draft.expectedSalary)
                      : ""
                  }
                  onChange={(e) =>
                    set(
                      "expectedSalary",
                      e.target.value.replace(/\D/g, "").slice(0, 12),
                    )
                  }
                />
                <div className="bg-muted inline-flex shrink-0 items-center rounded-lg p-0.5 text-sm font-semibold">
                  {["UZS", "USD"].map((c) => (
                    <button
                      key={c}
                      type="button"
                      onClick={() => set("currency", c)}
                      className={cn(
                        "rounded-md px-3 py-1.5 transition-colors",
                        draft.currency === c
                          ? "bg-background text-foreground shadow-sm"
                          : "text-muted-foreground",
                      )}
                    >
                      {c}
                    </button>
                  ))}
                </div>
              </div>
            </Field>
            <Field label={t("summaryLabel")}>
              <textarea
                rows={5}
                className={cn(
                  inputClass,
                  "h-auto min-h-[7rem] py-2.5 leading-relaxed",
                )}
                placeholder={t("summaryHint")}
                value={draft.summary}
                // A manual edit makes it the seeker's own words → clear the AI
                // flag (they've taken ownership).
                onChange={(e) =>
                  setDraft((d) => ({
                    ...d,
                    summary: e.target.value,
                    summaryAiGenerated: false,
                  }))
                }
              />
              <div className="mt-2 flex flex-wrap items-center gap-2">
                <button
                  type="button"
                  onClick={writeSummaryWithAi}
                  disabled={aiPending}
                  className={cn(
                    buttonVariants({ variant: "outline", size: "sm" }),
                  )}
                >
                  {aiPending ? (
                    <Loader2 className="size-4 animate-spin" />
                  ) : (
                    <Sparkles className="size-4" />
                  )}
                  {aiPending ? t("aiWriting") : t("aiWrite")}
                </button>
                <span className="text-muted-foreground text-xs">
                  {t("aiHint")}
                </span>
              </div>
              {/* Keep it honest — the AI is a helper, not a fabricator. */}
              <p className="text-muted-foreground mt-2 flex items-start gap-1.5 text-xs">
                <ShieldCheck className="text-primary mt-px size-3.5 shrink-0" />
                {draft.summaryAiGenerated
                  ? t("aiRealityCheckOn")
                  : t("aiRealityCheck")}
              </p>
              {aiFellBack ? (
                <p className="text-muted-foreground mt-1.5 text-xs">
                  {t("aiFellBack")}
                </p>
              ) : null}
            </Field>
          </>
        ) : null}

        {step === 2 ? (
          <>
            {draft.educations.map((edu, i) => (
              <div key={i} className="border-border rounded-xl border p-4">
                <div className="mb-3 flex items-center justify-between">
                  <span className="text-foreground text-sm font-semibold">
                    {t("education")} #{i + 1}
                  </span>
                  <button
                    type="button"
                    onClick={() => removeEdu(i)}
                    aria-label={t("remove")}
                    className="text-muted-foreground hover:text-destructive"
                  >
                    <Trash2 className="size-4" />
                  </button>
                </div>
                <div className="space-y-3">
                  <input
                    className={inputClass}
                    placeholder={t("school")}
                    value={edu.school}
                    onChange={(e) => setEdu(i, "school", e.target.value)}
                  />
                  <div className="grid gap-3 sm:grid-cols-2">
                    <input
                      className={inputClass}
                      placeholder={t("degree")}
                      value={edu.degree}
                      onChange={(e) => setEdu(i, "degree", e.target.value)}
                    />
                    <input
                      className={inputClass}
                      placeholder={t("field")}
                      value={edu.field}
                      onChange={(e) => setEdu(i, "field", e.target.value)}
                    />
                  </div>
                  <div className="grid gap-3 sm:grid-cols-2">
                    <YearSelect
                      label={t("startYear")}
                      value={edu.startYear}
                      onChange={(v) => setEdu(i, "startYear", v)}
                    />
                    <YearSelect
                      label={t("endYear")}
                      value={edu.endYear}
                      disabled={edu.isCurrent}
                      onChange={(v) => setEdu(i, "endYear", v)}
                    />
                  </div>
                  <label className="text-foreground flex items-center gap-2 text-sm">
                    <input
                      type="checkbox"
                      checked={edu.isCurrent}
                      onChange={(e) => setEdu(i, "isCurrent", e.target.checked)}
                    />
                    {t("studying")}
                  </label>
                </div>
              </div>
            ))}
            <button
              type="button"
              onClick={addEdu}
              className="border-border text-foreground hover:border-primary/40 inline-flex items-center gap-2 rounded-lg border border-dashed px-4 py-2 text-sm font-medium"
            >
              <Plus className="size-4" /> {t("addEducation")}
            </button>

            {/* Certificates & courses (with / without expiry) — certifications. */}
            <div>
              <p className="text-foreground mb-2 text-sm font-medium">
                {t("certificates")}
              </p>
              {draft.certificates.map((cert, i) => (
                <div
                  key={i}
                  className="border-border mb-3 rounded-xl border p-4"
                >
                  <div className="mb-3 flex items-center justify-between">
                    <span className="text-foreground text-sm font-semibold">
                      {t("certificate")} #{i + 1}
                    </span>
                    <button
                      type="button"
                      onClick={() => removeCert(i)}
                      aria-label={t("remove")}
                      className="text-muted-foreground hover:text-destructive"
                    >
                      <Trash2 className="size-4" />
                    </button>
                  </div>
                  <div className="space-y-3">
                    <input
                      className={inputClass}
                      placeholder={t("certName")}
                      value={cert.name}
                      onChange={(e) => setCert(i, "name", e.target.value)}
                    />
                    <input
                      className={inputClass}
                      placeholder={t("issuer")}
                      value={cert.issuer}
                      onChange={(e) => setCert(i, "issuer", e.target.value)}
                    />
                    <div className="grid gap-3 sm:grid-cols-2">
                      <YearSelect
                        label={t("issuedYear")}
                        value={cert.issuedYear}
                        onChange={(v) => setCert(i, "issuedYear", v)}
                      />
                      {/* Certificates may expire after today, unlike a job or
                          a degree — so this one list runs forward as well. */}
                      <YearSelect
                        label={t("expiryYear")}
                        value={cert.expiryYear}
                        future={10}
                        onChange={(v) => setCert(i, "expiryYear", v)}
                      />
                    </div>
                    <p className="text-muted-foreground text-xs">
                      {t("expiryHint")}
                    </p>
                  </div>
                </div>
              ))}
              <button
                type="button"
                onClick={addCert}
                className="border-border text-foreground hover:border-primary/40 inline-flex items-center gap-2 rounded-lg border border-dashed px-4 py-2 text-sm font-medium"
              >
                <Plus className="size-4" /> {t("addCertificate")}
              </button>
            </div>

            <div>
              <p className="text-foreground mb-3 text-sm font-medium">
                {t("languages")}
              </p>
              <div className="space-y-3">
                {LANGS.map((code) => (
                  <div
                    key={code}
                    className="flex flex-col gap-2 sm:flex-row sm:items-center"
                  >
                    <span className="text-foreground w-24 shrink-0 text-sm">
                      {t(`lang.${code}`)}
                    </span>
                    <div className="flex flex-wrap gap-1.5">
                      {LEVELS.map((lvl) => {
                        const on = (draft.languages[code] ?? "none") === lvl;
                        return (
                          <button
                            key={lvl}
                            type="button"
                            onClick={() => setLang(code, lvl)}
                            className={cn(
                              "rounded-full border px-2.5 py-1 text-xs font-medium transition-colors",
                              on
                                ? "border-primary bg-primary text-primary-foreground"
                                : "border-border bg-background text-muted-foreground hover:border-primary/40",
                            )}
                          >
                            {t(`level.${lvl}`)}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                ))}
                {/* Languages the seeker added themselves (stored by name). */}
                {Object.keys(draft.languages)
                  .filter((k) => !LANGS.includes(k as (typeof LANGS)[number]))
                  .map((code) => (
                    <div
                      key={code}
                      className="flex flex-col gap-2 sm:flex-row sm:items-center"
                    >
                      <span className="text-foreground flex w-24 shrink-0 items-center gap-1 text-sm">
                        {code}
                        <button
                          type="button"
                          onClick={() => removeLang(code)}
                          aria-label={t("remove")}
                          className="text-muted-foreground hover:text-destructive"
                        >
                          <X className="size-3" />
                        </button>
                      </span>
                      <div className="flex flex-wrap gap-1.5">
                        {LEVELS.filter((l) => l !== "none").map((lvl) => {
                          const on = draft.languages[code] === lvl;
                          return (
                            <button
                              key={lvl}
                              type="button"
                              onClick={() => setLang(code, lvl)}
                              className={cn(
                                "rounded-full border px-2.5 py-1 text-xs font-medium transition-colors",
                                on
                                  ? "border-primary bg-primary text-primary-foreground"
                                  : "border-border bg-background text-muted-foreground hover:border-primary/40",
                              )}
                            >
                              {t(`level.${lvl}`)}
                            </button>
                          );
                        })}
                      </div>
                    </div>
                  ))}
              </div>
              {/* Add any other language */}
              <div className="mt-3 flex gap-2">
                <input
                  className={inputClass}
                  placeholder={t("addLanguageHint")}
                  value={newLang}
                  onChange={(e) => setNewLang(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") {
                      e.preventDefault();
                      addLang();
                    }
                  }}
                />
                <button
                  type="button"
                  onClick={addLang}
                  className="border-border text-foreground hover:border-primary/40 inline-flex shrink-0 items-center gap-1 rounded-lg border px-3 text-sm font-medium"
                >
                  <Plus className="size-4" /> {t("addLanguage")}
                </button>
              </div>
            </div>
          </>
        ) : null}

        {step === 3 ? (
          <>
            <Field label={t("phone")} required>
              {/* The number an employer will actually dial — see uz-phone.ts
                  for why it is collected as nine digits behind a pinned +998
                  rather than as free text. */}
              <UzPhoneInput
                value={draft.phone}
                onChange={(v) => set("phone", v)}
                required
              />
            </Field>
            <Field label={t("email")}>
              <input
                type="email"
                className={inputClass}
                value={draft.email}
                onChange={(e) => set("email", e.target.value)}
              />
            </Field>
          </>
        ) : null}

        {error ? (
          <p className="text-destructive text-sm">{t("errSave")}</p>
        ) : null}
      </div>

      <div className="mt-6 flex items-center justify-between">
        <button
          type="button"
          onClick={() => setStep((s) => Math.max(0, s - 1))}
          disabled={step === 0 || pending}
          className={cn(
            buttonVariants({ variant: "outline", size: "md" }),
            step === 0 && "invisible",
          )}
        >
          {t("back")}
        </button>
        <button
          type="button"
          onClick={next}
          disabled={!valid || pending}
          className={cn(buttonVariants({ variant: "primary", size: "md" }))}
        >
          {pending ? <Loader2 className="size-4 animate-spin" /> : null}
          {step === steps.length - 1 ? t("finish") : t("next")}
        </button>
      </div>
    </div>
  );
}
