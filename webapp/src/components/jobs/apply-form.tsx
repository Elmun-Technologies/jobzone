"use client";

import { Loader2 } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { useActionState, useEffect, useRef, useState } from "react";

// Locale-aware router so the sign-in detour keeps the active locale (the plain
// next/navigation router dropped the prefix → /uz guest landed on a re-resolved
// /sign-in in the wrong language).
import { useRouter } from "@/i18n/navigation";

import { buttonVariants } from "@/components/ui/button";
import { applyToJob, type ApplyState } from "@/lib/actions/apply";
import type { ScreeningQuestion } from "@/lib/data/types";
import { cn } from "@/lib/utils";

const fieldClass =
  "w-full rounded-lg border border-border bg-background p-3 text-foreground outline-none focus-visible:ring-2 focus-visible:ring-ring";

// Where an in-progress application is parked while a guest signs in at
// submit-time (keyed per job so applying to several jobs as a guest, one
// after another, can't cross-contaminate).
const stashKey = (jobId: string) => `yolla-apply-draft:${jobId}`;

interface Stashed {
  coverLetter: string;
  answers: Record<string, string>;
}

export function ApplyForm({
  jobId,
  questions,
}: {
  jobId: string;
  questions: ScreeningQuestion[];
}) {
  const t = useTranslations("apply");
  const locale = useLocale();
  const router = useRouter();
  const [state, action, pending] = useActionState<ApplyState, FormData>(
    applyToJob,
    {},
  );
  const [restored, setRestored] = useState<Stashed | null>(null);
  const formRef = useRef<HTMLFormElement>(null);

  // Auth-last: if the guest signed in at submit-time and came back, restore
  // the cover letter + answers they'd filled (stashed below) so nothing is
  // lost to the sign-in detour — they just submit once more.
  useEffect(() => {
    const key = stashKey(jobId);
    const saved = sessionStorage.getItem(key);
    if (!saved) return;
    sessionStorage.removeItem(key);
    // Restoring client-only storage after mount is intentional here (a lazy
    // initializer would desync SSR hydration).
    try {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setRestored(JSON.parse(saved) as Stashed);
    } catch {
      // Ignore a malformed stash.
    }
  }, [jobId]);

  useEffect(() => {
    if (!state.signedOut || !formRef.current) return;
    const data = new FormData(formRef.current);
    const answers: Record<string, string> = {};
    for (const [key, value] of data.entries()) {
      if (key.startsWith("answer:"))
        answers[key.slice("answer:".length)] = value.toString();
    }
    sessionStorage.setItem(
      stashKey(jobId),
      JSON.stringify({
        coverLetter: (data.get("coverLetter") ?? "").toString(),
        answers,
      }),
    );
    router.push(
      `/sign-in?next=${encodeURIComponent(`/${locale}/jobs/${jobId}/apply`)}`,
    );
  }, [state.signedOut, jobId, locale, router]);

  const errorMsg =
    state.error === "duplicate"
      ? t("errDuplicate")
      : state.error
        ? t("errUnknown")
        : undefined;

  return (
    <form
      // Uncontrolled fields only read defaultValue on mount, so a fresh key
      // forces a remount once the restored draft lands (a moment after the
      // initial paint) — otherwise a value restored via sessionStorage would
      // never reach the DOM.
      key={restored ? "restored" : "initial"}
      ref={formRef}
      action={action}
      className="flex flex-col gap-5"
    >
      <input type="hidden" name="jobId" value={jobId} />
      <input type="hidden" name="locale" value={locale} />

      <label className="block">
        <span className="text-foreground mb-1 block text-sm font-medium">
          {t("coverLetter")}{" "}
          <span className="text-muted-foreground">({t("optional")})</span>
        </span>
        <textarea
          name="coverLetter"
          rows={6}
          defaultValue={restored?.coverLetter}
          placeholder={t("coverLetterPlaceholder")}
          className={fieldClass}
        />
      </label>

      {questions.map((q) => (
        <label key={q.id} className="block">
          <span className="text-foreground mb-1 block text-sm font-medium">
            {q.label}
            {q.required ? " *" : ""}
          </span>
          {q.type === "yesno" ? (
            <select
              name={`answer:${q.id}`}
              required={q.required}
              defaultValue={restored?.answers[q.id] ?? ""}
              className={cn(fieldClass, "h-11")}
            >
              <option value="" disabled>
                —
              </option>
              <option value="yes">{t("yes")}</option>
              <option value="no">{t("no")}</option>
            </select>
          ) : q.type === "choice" && q.options && q.options.length > 0 ? (
            <select
              name={`answer:${q.id}`}
              required={q.required}
              defaultValue={restored?.answers[q.id] ?? ""}
              className={cn(fieldClass, "h-11")}
            >
              <option value="" disabled>
                —
              </option>
              {q.options.map((opt) => (
                <option key={opt} value={opt}>
                  {opt}
                </option>
              ))}
            </select>
          ) : (
            <input
              name={`answer:${q.id}`}
              type="text"
              required={q.required}
              defaultValue={restored?.answers[q.id]}
              className={cn(fieldClass, "h-11")}
            />
          )}
        </label>
      ))}

      {errorMsg ? (
        <p className="text-destructive text-sm font-medium">{errorMsg}</p>
      ) : null}

      <button
        type="submit"
        disabled={pending}
        className={cn(buttonVariants({ variant: "primary", size: "lg" }))}
      >
        {pending ? <Loader2 className="size-4 animate-spin" /> : null}
        {t("submit")}
      </button>
    </form>
  );
}
