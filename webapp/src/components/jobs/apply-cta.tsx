"use client";

import { useTranslations } from "next-intl";
import { useEffect, useState } from "react";

import { useSession } from "@/components/auth/session-provider";
import { QuickApplyButton } from "@/components/jobs/quick-apply-button";
import { createClient } from "@/lib/supabase/client";

/**
 * The vacancy page's primary action: "apply", or "you already applied".
 *
 * Which of the two it is depends on the visitor, and the vacancy page is the
 * site's largest indexable surface — so the question is asked in the browser
 * rather than on the server, which is what lets the page itself be prerendered
 * and served from the CDN.
 *
 * Until the answer arrives it shows the button. That is the honest default: it
 * is an offer to act, not a claim about who is looking, and a seeker who did
 * already apply gets the inline "already applied" tick from `quickApply`
 * instead of a duplicate.
 */
export function ApplyCta({
  jobId,
  needsForm,
  className,
}: {
  jobId: string;
  needsForm: boolean;
  className?: string;
}) {
  const t = useTranslations("jobs");
  const { signedIn, userId } = useSession();
  const [applied, setApplied] = useState(false);

  useEffect(() => {
    if (!signedIn || !userId) return;
    let cancelled = false;
    (async () => {
      try {
        const supabase = createClient();
        // Scoped to the caller explicitly, not left to RLS: the policy also
        // lets a job's owner read every application for it (0003), so filtering
        // on job_id alone would return other people's rows on the employer's
        // own vacancy — and `maybeSingle()` would then throw on the second.
        const { data } = await supabase
          .from("applications")
          .select("id")
          .eq("job_id", jobId)
          .eq("applicant_id", userId)
          .maybeSingle();
        if (!cancelled && data) setApplied(true);
      } catch {
        // Leave the button up — worst case they tap it and get the tick.
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [jobId, signedIn, userId]);

  if (applied) {
    return (
      <p className="bg-muted text-muted-foreground mt-4 w-full rounded-full py-3 text-center text-sm font-semibold">
        {t("applied")}
      </p>
    );
  }

  return (
    <QuickApplyButton
      jobId={jobId}
      needsForm={needsForm}
      className={className}
    />
  );
}
