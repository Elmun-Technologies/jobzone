"use client";

import { useLocale, useTranslations } from "next-intl";
import { useState, useTransition } from "react";

import { toast } from "@/components/ui/toast";
import { withdrawApplication } from "@/lib/actions/application-status";
import { useRouter } from "@/i18n/navigation";

/**
 * Lets an applicant take back an application they sent by mistake.
 *
 * Confirms first: withdrawing is one-way — the unique (job_id, applicant_id)
 * constraint means the same job can't be applied to again afterwards.
 */
export function WithdrawApplicationButton({
  applicationId,
}: {
  applicationId: string;
}) {
  const t = useTranslations("applications");
  const locale = useLocale();
  const router = useRouter();
  const [confirming, setConfirming] = useState(false);
  const [pending, startTransition] = useTransition();

  function withdraw() {
    startTransition(async () => {
      const res = await withdrawApplication(applicationId, locale);
      setConfirming(false);
      if (res.ok) {
        toast({ title: t("withdrawnToast"), variant: "success" });
        router.refresh();
      } else {
        toast({ title: t("withdrawFailed"), variant: "error" });
      }
    });
  }

  if (!confirming) {
    return (
      <button
        type="button"
        onClick={() => setConfirming(true)}
        className="text-muted-foreground hover:text-destructive shrink-0 text-xs font-semibold underline underline-offset-4 transition-colors"
      >
        {t("withdraw")}
      </button>
    );
  }

  return (
    <span className="flex shrink-0 items-center gap-2 text-xs">
      <span className="text-muted-foreground">{t("withdrawConfirm")}</span>
      <button
        type="button"
        onClick={withdraw}
        disabled={pending}
        className="text-destructive font-semibold underline underline-offset-4 disabled:opacity-50"
      >
        {t("withdrawYes")}
      </button>
      <button
        type="button"
        onClick={() => setConfirming(false)}
        disabled={pending}
        className="text-muted-foreground hover:text-foreground font-semibold underline underline-offset-4 disabled:opacity-50"
      >
        {t("withdrawNo")}
      </button>
    </span>
  );
}
