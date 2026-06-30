"use client";

import { Check, Plus, Trash2 } from "lucide-react";
import { useTranslations } from "next-intl";
import { useState, useTransition } from "react";

import { buttonVariants } from "@/components/ui/button";
import { useRouter } from "@/i18n/navigation";
import { saveResume } from "@/lib/actions/resume";
import type { EducationEntry, ResumeDraft } from "@/lib/data/resume";
import { cn } from "@/lib/utils";

const inputClass =
  "border-border bg-background text-foreground placeholder:text-muted-foreground focus-visible:ring-ring h-11 w-full rounded-lg border px-3 text-sm focus-visible:ring-2 focus-visible:outline-none";

const EXP = ["none", "under_1", "1_3", "3_5", "5_plus"] as const;
const MARITAL = ["single", "married", "divorced"] as const;
const LANGS = ["ru", "en", "tr", "tg", "uz"] as const;
const LEVELS = ["none", "a1_a2", "b1_b2", "c1_c2", "native"] as const;

const EMPTY_EDU: EducationEntry = {
  school: "",
  degree: "",
  field: "",
  startYear: "",
  endYear: "",
  isCurrent: false,
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

export function ResumeWizard({ initial }: { initial: ResumeDraft }) {
  const t = useTranslations("resume");
  const router = useRouter();
  const [step, setStep] = useState(0);
  const [draft, setDraft] = useState<ResumeDraft>(initial);
  const [error, setError] = useState(false);
  const [pending, start] = useTransition();

  const set = <K extends keyof ResumeDraft>(key: K, value: ResumeDraft[K]) =>
    setDraft((d) => ({ ...d, [key]: value }));

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

  const steps = [
    t("stepPersonal"),
    t("stepExperience"),
    t("stepEducation"),
    t("stepContacts"),
  ];

  const valid =
    step === 0
      ? draft.position.trim() !== "" && draft.fullName.trim() !== ""
      : step === 1
        ? draft.experienceLevel !== ""
        : step === 3
          ? draft.phone.trim() !== ""
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
      if (res.signedOut) router.push("/sign-in");
      else if (res.error) setError(true);
      else router.push("/account");
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
            {i < steps.length - 1 ? (
              <span className="bg-border mx-1 h-px w-6" />
            ) : null}
          </li>
        ))}
      </ol>

      <div className="border-border bg-card mt-8 space-y-5 rounded-2xl border p-6">
        {step === 0 ? (
          <>
            <Field label={t("position")} required>
              <input
                className={inputClass}
                placeholder={t("positionHint")}
                value={draft.position}
                onChange={(e) => set("position", e.target.value)}
              />
            </Field>
            <Field label={t("fullName")} required>
              <input
                className={inputClass}
                value={draft.fullName}
                onChange={(e) => set("fullName", e.target.value)}
              />
            </Field>
            <div className="grid gap-5 sm:grid-cols-2">
              <Field label={t("birthDate")}>
                <input
                  type="date"
                  className={inputClass}
                  value={draft.birthDate}
                  onChange={(e) => set("birthDate", e.target.value)}
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
            <Field label={t("city")}>
              <input
                className={inputClass}
                value={draft.city}
                onChange={(e) => set("city", e.target.value)}
              />
            </Field>
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
            <Field label={t("expectedSalary")}>
              <div className="flex gap-2">
                <input
                  type="number"
                  inputMode="numeric"
                  min={0}
                  className={inputClass}
                  placeholder={t("salaryHint")}
                  value={draft.expectedSalary}
                  onChange={(e) => set("expectedSalary", e.target.value)}
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
                    <input
                      className={inputClass}
                      inputMode="numeric"
                      placeholder={t("startYear")}
                      value={edu.startYear}
                      onChange={(e) => setEdu(i, "startYear", e.target.value)}
                    />
                    <input
                      className={inputClass}
                      inputMode="numeric"
                      placeholder={t("endYear")}
                      disabled={edu.isCurrent}
                      value={edu.isCurrent ? "" : edu.endYear}
                      onChange={(e) => setEdu(i, "endYear", e.target.value)}
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
              </div>
            </div>
          </>
        ) : null}

        {step === 3 ? (
          <>
            <Field label={t("phone")} required>
              <input
                type="tel"
                className={inputClass}
                placeholder="+998 90 123 45 67"
                value={draft.phone}
                onChange={(e) => set("phone", e.target.value)}
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
          {step === steps.length - 1 ? t("finish") : t("next")}
        </button>
      </div>
    </div>
  );
}
