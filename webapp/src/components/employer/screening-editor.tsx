"use client";

import { Plus, Trash2, X } from "lucide-react";
import { useTranslations } from "next-intl";
import { useState } from "react";

import { cn } from "@/lib/utils";

type QType = "text" | "choice" | "yesno";
interface Q {
  /** Preserved across edits so applicants' stored answers (keyed by this id in
   * applications.answers) keep matching their question. New rows have none. */
  id?: string;
  label: string;
  type: QType;
  required: boolean;
  options: string[];
}

export interface StashedQuestion {
  id?: string;
  label: string;
  type: QType;
  required: boolean;
  options?: string[];
}

const EMPTY_Q: Q = {
  label: "",
  type: "text",
  required: false,
  options: ["", ""],
};
const TYPES: QType[] = ["text", "choice", "yesno"];

const inputClass =
  "h-11 w-full rounded-lg border border-border bg-background px-3 text-sm text-foreground outline-none focus-visible:ring-2 focus-visible:ring-ring";

/**
 * Optional screening-questions editor. Maintains the question array locally and
 * mirrors it into a hidden input as JSON (shape: {id,label,type,required,
 * options?}) so it posts with the job form and lands in jobs.screening_questions.
 */
export function ScreeningEditor({
  initialQuestions = [],
}: {
  initialQuestions?: StashedQuestion[];
}) {
  const t = useTranslations("employer.post");
  const [qs, setQs] = useState<Q[]>(() =>
    initialQuestions.map((q) => ({
      id: q.id,
      label: q.label,
      type: q.type,
      required: q.required,
      options: q.options && q.options.length > 0 ? q.options : ["", ""],
    })),
  );

  const update = (i: number, patch: Partial<Q>) =>
    setQs((prev) => prev.map((q, j) => (j === i ? { ...q, ...patch } : q)));

  const payload = qs
    .filter((q) => q.label.trim() !== "")
    .map((q, i) => ({
      // Keep an existing question's id (so already-submitted answers stay
      // matched); only mint qN for a newly added one.
      id: q.id ?? `q${i + 1}`,
      label: q.label.trim(),
      type: q.type,
      required: q.required,
      ...(q.type === "choice"
        ? { options: q.options.map((o) => o.trim()).filter(Boolean) }
        : {}),
    }));

  return (
    <section className="border-border bg-card rounded-2xl border p-5">
      <h2 className="text-foreground text-lg font-bold">
        {t("screening")}{" "}
        <span className="text-muted-foreground text-sm font-normal">
          {t("optional")}
        </span>
      </h2>
      <p className="text-muted-foreground mt-0.5 mb-4 text-sm">
        {t("screeningSub")}
      </p>

      <input
        type="hidden"
        name="screeningQuestions"
        value={JSON.stringify(payload)}
      />

      <div className="space-y-4">
        {qs.map((q, i) => (
          <div key={i} className="border-border rounded-xl border p-4">
            <div className="flex items-start gap-2">
              <span className="text-muted-foreground pt-2.5 text-sm font-semibold">
                {i + 1}.
              </span>
              <textarea
                rows={2}
                placeholder={t("questionHint")}
                value={q.label}
                onChange={(e) => update(i, { label: e.target.value })}
                className="border-border bg-background text-foreground focus-visible:ring-ring w-full rounded-lg border px-3 py-2 text-sm outline-none focus-visible:ring-2"
              />
              <button
                type="button"
                onClick={() => setQs((p) => p.filter((_, j) => j !== i))}
                aria-label={t("remove")}
                className="text-muted-foreground hover:text-destructive pt-2.5"
              >
                <Trash2 className="size-4" />
              </button>
            </div>

            <div className="mt-3 flex flex-wrap gap-2 pl-6">
              {TYPES.map((ty) => (
                <button
                  key={ty}
                  type="button"
                  onClick={() => update(i, { type: ty })}
                  className={cn(
                    "rounded-full border px-3 py-1.5 text-xs font-medium transition-colors",
                    q.type === ty
                      ? "border-primary bg-primary text-primary-foreground"
                      : "border-border bg-background text-muted-foreground hover:border-primary/40",
                  )}
                >
                  {t(`qtype.${ty}`)}
                </button>
              ))}
            </div>

            {q.type === "choice" ? (
              <div className="mt-3 space-y-2 pl-6">
                {q.options.map((opt, oi) => (
                  <div key={oi} className="flex items-center gap-2">
                    <input
                      placeholder={t("optionHint")}
                      value={opt}
                      onChange={(e) =>
                        update(i, {
                          options: q.options.map((o, oj) =>
                            oj === oi ? e.target.value : o,
                          ),
                        })
                      }
                      className={inputClass}
                    />
                    <button
                      type="button"
                      onClick={() =>
                        update(i, {
                          options: q.options.filter((_, oj) => oj !== oi),
                        })
                      }
                      aria-label={t("remove")}
                      className="text-muted-foreground hover:text-destructive"
                    >
                      <X className="size-4" />
                    </button>
                  </div>
                ))}
                <button
                  type="button"
                  onClick={() => update(i, { options: [...q.options, ""] })}
                  className="text-primary inline-flex items-center gap-1 text-sm font-medium"
                >
                  <Plus className="size-4" /> {t("addOption")}
                </button>
              </div>
            ) : null}

            <label className="text-foreground mt-3 flex items-center gap-2 pl-6 text-sm">
              <input
                type="checkbox"
                checked={q.required}
                onChange={(e) => update(i, { required: e.target.checked })}
                className="size-4"
              />
              {t("required")}
            </label>
          </div>
        ))}

        <button
          type="button"
          onClick={() => setQs((p) => [...p, { ...EMPTY_Q }])}
          className="border-border text-foreground hover:border-primary/40 inline-flex items-center gap-2 rounded-lg border border-dashed px-4 py-2 text-sm font-medium"
        >
          <Plus className="size-4" /> {t("addQuestion")}
        </button>
      </div>
    </section>
  );
}
