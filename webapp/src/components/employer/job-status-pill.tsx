const STATUS_CLASS: Record<string, string> = {
  open: "bg-emerald-100 text-emerald-700 dark:bg-emerald-950 dark:text-emerald-300",
  draft: "bg-muted text-muted-foreground",
  closed: "bg-red-100 text-red-700 dark:bg-red-950 dark:text-red-300",
  blocked: "bg-red-100 text-red-700 dark:bg-red-950 dark:text-red-300",
};

/** Colored status pill for a job row — shared by "My jobs" and the dashboard. */
export function JobStatusPill({
  status,
  label,
}: {
  status: string;
  label: string;
}) {
  return (
    <span
      className={`shrink-0 rounded-full px-2.5 py-1 text-xs font-semibold ${
        STATUS_CLASS[status] ?? STATUS_CLASS.draft
      }`}
    >
      {label}
    </span>
  );
}
