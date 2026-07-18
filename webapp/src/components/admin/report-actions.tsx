"use client";

import { useTransition } from "react";

import { resolveReport } from "@/lib/actions/admin/reports";

/**
 * Three-button row on each open report: mark reviewed / dismiss / action
 * taken. All three go through admin_resolve_report() → admin_audit(); the
 * table refreshes via `revalidatePath("/admin/reports")` inside the action.
 */
export function ReportActions({ reportId }: { reportId: number }) {
  const [pending, start] = useTransition();
  const s = {
    review: "Ko'rildi",
    dismiss: "Rad etish",
    actionTaken: "Chora ko'rildi",
  };
  return (
    <div className="flex flex-wrap gap-2">
      <button
        type="button"
        disabled={pending}
        onClick={() =>
          start(async () => {
            await resolveReport(reportId, "reviewed");
          })
        }
        className="rounded-md border border-border px-2 py-1 text-xs disabled:opacity-40"
      >
        {s.review}
      </button>
      <button
        type="button"
        disabled={pending}
        onClick={() =>
          start(async () => {
            await resolveReport(reportId, "dismissed");
          })
        }
        className="rounded-md border border-border px-2 py-1 text-xs disabled:opacity-40"
      >
        {s.dismiss}
      </button>
      <button
        type="button"
        disabled={pending}
        onClick={() =>
          start(async () => {
            await resolveReport(reportId, "action_taken");
          })
        }
        className="rounded-md bg-destructive text-destructive-foreground px-2 py-1 text-xs font-semibold disabled:opacity-40"
      >
        {s.actionTaken}
      </button>
    </div>
  );
}
