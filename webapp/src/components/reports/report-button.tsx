"use client";

import { Flag } from "lucide-react";
import { useTranslations } from "next-intl";
import { useActionState, useState } from "react";

import {
  submitReportAction,
  type ReportFormState,
  type ReportReason,
  type ReportTargetType,
} from "@/lib/actions/reports";

const REASONS: ReportReason[] = [
  "spam",
  "scam",
  "misleading",
  "discrimination",
  "illegal",
  "inappropriate",
  "personal_info",
  "other",
];

/**
 * "Report content" button that mounts a modal with the reason picker +
 * details field. Rendered on job/company detail pages so any signed-in
 * user can flag inappropriate content — the Apple 1.2 requirement for
 * UGC apps ("provide a mechanism to report objectionable content").
 *
 * A guest sees the button but the modal explains sign-in is required —
 * we don't hide it because Apple review will look for the flag icon
 * on the detail pages.
 */
export function ReportButton({
  targetType,
  targetId,
  className,
}: {
  targetType: ReportTargetType;
  targetId: string;
  className?: string;
}) {
  const t = useTranslations("report");
  const [open, setOpen] = useState(false);
  const initial: ReportFormState = {};
  const [state, action, pending] = useActionState(submitReportAction, initial);

  const errorMsg = state.error
    ? state.error === "no_session"
      ? t("errNoSession")
      : state.error === "invalid"
        ? t("errInvalid")
        : t("errUnknown")
    : undefined;

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className={
          className ??
          "text-muted-foreground hover:text-destructive inline-flex items-center gap-1 text-xs"
        }
        aria-label={t("openDialog")}
      >
        <Flag className="size-3.5" aria-hidden />
        {t("cta")}
      </button>

      {open ? (
        <div
          className="fixed inset-0 z-[100] flex items-center justify-center bg-black/50 p-4"
          role="dialog"
          aria-labelledby="report-title"
          onClick={(e) => {
            if (e.target === e.currentTarget) setOpen(false);
          }}
        >
          <div className="bg-background border-border w-full max-w-md rounded-2xl border p-5 shadow-2xl">
            <h2
              id="report-title"
              className="text-foreground text-lg font-semibold"
            >
              {t("title")}
            </h2>
            <p className="text-muted-foreground mt-1 text-sm">{t("subtitle")}</p>

            {state.ok ? (
              <div className="mt-4">
                <p className="text-foreground text-sm">{t("sent")}</p>
                <div className="mt-4 flex justify-end">
                  <button
                    type="button"
                    onClick={() => setOpen(false)}
                    className="bg-primary text-primary-foreground rounded-md px-4 py-2 text-sm font-semibold"
                  >
                    {t("close")}
                  </button>
                </div>
              </div>
            ) : (
              <form action={action} className="mt-4 space-y-3">
                <input type="hidden" name="targetType" value={targetType} />
                <input type="hidden" name="targetId" value={targetId} />
                <fieldset>
                  <legend className="text-foreground mb-2 text-sm font-medium">
                    {t("reasonLegend")}
                  </legend>
                  <div className="space-y-1.5">
                    {REASONS.map((r) => (
                      <label
                        key={r}
                        className="text-foreground flex cursor-pointer items-center gap-2 text-sm"
                      >
                        <input
                          type="radio"
                          name="reason"
                          value={r}
                          required
                          className="size-4"
                        />
                        {t(`reason.${r}`)}
                      </label>
                    ))}
                  </div>
                </fieldset>
                <label className="text-foreground block text-sm font-medium">
                  {t("detailsLabel")}
                  <textarea
                    name="details"
                    rows={3}
                    maxLength={500}
                    placeholder={t("detailsPlaceholder")}
                    className="border-border bg-background text-foreground mt-1 block w-full rounded-md border p-2 text-sm"
                  />
                </label>
                {errorMsg ? (
                  <p className="text-destructive text-sm" role="alert">
                    {errorMsg}
                  </p>
                ) : null}
                <div className="mt-4 flex justify-end gap-2">
                  <button
                    type="button"
                    onClick={() => setOpen(false)}
                    className="text-muted-foreground rounded-md border border-border px-3 py-2 text-sm"
                  >
                    {t("cancel")}
                  </button>
                  <button
                    type="submit"
                    disabled={pending}
                    className="bg-destructive text-destructive-foreground rounded-md px-4 py-2 text-sm font-semibold disabled:opacity-40"
                  >
                    {pending ? t("sending") : t("submit")}
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      ) : null}
    </>
  );
}
