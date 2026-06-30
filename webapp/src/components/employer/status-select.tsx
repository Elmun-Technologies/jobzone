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
  const [status, setStatus] = useState(initial);
  const [pending, startTransition] = useTransition();

  function onChange(event: React.ChangeEvent<HTMLSelectElement>) {
    const next = event.target.value;
    const prev = status;
    setStatus(next);
    startTransition(async () => {
      const result = await setApplicationStatus(applicationId, next);
      if (!result.ok) setStatus(prev);
    });
  }

  return (
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
  );
}
