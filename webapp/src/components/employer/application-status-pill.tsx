const STATUS_CLASS: Record<string, string> = {
  submitted: "bg-muted text-muted-foreground",
  viewed: "bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-300",
  shortlisted: "bg-accent text-accent-foreground",
  interview:
    "bg-amber-100 text-amber-700 dark:bg-amber-950 dark:text-amber-300",
  offer:
    "bg-emerald-100 text-emerald-700 dark:bg-emerald-950 dark:text-emerald-300",
  hired:
    "bg-emerald-100 text-emerald-700 dark:bg-emerald-950 dark:text-emerald-300",
  rejected: "bg-red-100 text-red-700 dark:bg-red-950 dark:text-red-300",
  withdrawn: "bg-muted text-muted-foreground",
};

/** Colored application-status pill — shared by "My applications" (seeker) and
 *  the employer candidates surfaces so the color language stays consistent. */
export function ApplicationStatusPill({
  status,
  label,
}: {
  status: string;
  label: string;
}) {
  return (
    <span
      className={`shrink-0 rounded-full px-2.5 py-1 text-xs font-semibold ${
        STATUS_CLASS[status] ?? STATUS_CLASS.submitted
      }`}
    >
      {label}
    </span>
  );
}
