"use client";

import { useTranslations } from "next-intl";
import { useState, useTransition } from "react";

import { setApplicationStatus } from "@/lib/actions/application-status";

const STATUSES = [
  "submitted",
  "viewed",
  "shortlisted",
  "interview",
  "offer",
  "rejected",
  "hired",
];

/** Employer status changer for one application (persists via Server Action). */
export function StatusSelect({
  applicationId,
  initial,
}: {
  applicationId: string;
  initial: string;
}) {
  const t = useTranslations("applications");
  const tc = useTranslations("common");
  const [status, setStatus] = useState(initial);
  const [failed, setFailed] = useState(false);
  const [pending, startTransition] = useTransition();

  function onChange(event: React.ChangeEvent<HTMLSelectElement>) {
    const next = event.target.value;
    const prev = status;
    setStatus(next);
    setFailed(false);
    startTransition(async () => {
      const result = await setApplicationStatus(applicationId, next);
      // Revert AND tell the employer — a silent snap-back read as "it saved".
      if (!result.ok) {
        setStatus(prev);
        setFailed(true);
      }
    });
  }

  return (
    <div className="flex flex-col items-end gap-1">
      <select
        value={status}
        onChange={onChange}
        disabled={pending}
        aria-label={t("title")}
        className="border-border bg-background text-foreground focus-visible:ring-ring h-9 rounded-lg border px-2 text-sm focus-visible:ring-2 focus-visible:outline-none disabled:opacity-60"
      >
        {STATUSES.map((s) => (
          <option key={s} value={s}>
            {t(`status.${s}`)}
          </option>
        ))}
      </select>
      {failed ? (
        <span role="alert" className="text-destructive text-xs">
          {tc("error")}
        </span>
      ) : null}
    </div>
  );
}
