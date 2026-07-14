"use client";

import { Check, Loader2, Zap } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";

import { quickApply } from "@/lib/actions/apply";
import { track } from "@/lib/analytics/track";
import { cn } from "@/lib/utils";

/**
 * One-tap "apply with my résumé" button — the payoff of the map's "find a job,
 * apply in one tap" promise. Attempts quickApply; anything it can't satisfy is
 * routed, not dropped:
 *  - signedOut → sign-in (comes back to the apply page),
 *  - needsResume → the résumé builder,
 *  - needsForm (required screening / cover letter) → the full apply form,
 *  - ok / duplicate → shows an inline ✓ so the seeker can keep browsing.
 * `needsForm` is also known to the caller (from the job's screening), so an
 * ineligible job renders as a plain link to the form instead of a dead tap.
 */
export function QuickApplyButton({
  jobId,
  needsForm = false,
  className,
}: {
  jobId: string;
  /** The job has required screening / wants a cover letter — go straight to
   * the form rather than attempting a one-tap apply. */
  needsForm?: boolean;
  className?: string;
}) {
  const t = useTranslations("apply");
  const locale = useLocale();
  const router = useRouter();
  const [pending, start] = useTransition();
  const [applied, setApplied] = useState(false);

  const formHref = `/${locale}/jobs/${jobId}/apply`;
  const base =
    "inline-flex items-center justify-center gap-1.5 rounded-full font-semibold transition-opacity hover:opacity-90 disabled:opacity-60";

  function onClick() {
    // Fires the moment the seeker clicks "Apply" — the top-of-funnel signal
    // regardless of which branch the intent resolves to below.
    track("job_apply_click", { job_id: jobId, quick: !needsForm });
    if (needsForm) {
      router.push(formHref);
      return;
    }
    start(async () => {
      const res = await quickApply(jobId);
      if (res.signedOut) {
        router.push(`/${locale}/sign-in?next=${encodeURIComponent(formHref)}`);
      } else if (res.needsResume) {
        router.push(
          `/${locale}/resumes/new?next=${encodeURIComponent(formHref)}`,
        );
      } else if (res.needsForm) {
        router.push(formHref);
      } else if (res.ok || res.duplicate) {
        // Quick path completed without a form — treat as a full apply submit,
        // matching the full-form apply flow so the conversion count is
        // comparable across the two paths.
        track("job_apply_submit", {
          job_id: jobId,
          path: "quick",
          duplicate: res.duplicate === true,
        });
        setApplied(true);
      } else {
        // Unexpected failure — fall back to the full form.
        router.push(formHref);
      }
    });
  }

  if (applied) {
    return (
      <span
        className={cn(
          base,
          "bg-primary text-primary-foreground cursor-default",
          className,
        )}
      >
        <Check className="size-4" />
        {t("quickApplied")}
      </span>
    );
  }

  return (
    <button
      type="button"
      onClick={onClick}
      disabled={pending}
      className={cn(base, "bg-primary text-primary-foreground", className)}
    >
      {pending ? (
        <Loader2 className="size-4 animate-spin" />
      ) : needsForm ? null : (
        <Zap className="size-4" />
      )}
      {needsForm ? t("apply") : t("quickApply")}
    </button>
  );
}
