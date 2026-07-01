/** Labeled field wrapper for admin forms — keeps form markup declarative. */
export function FormField({
  label,
  hint,
  children,
}: {
  label: string;
  hint?: string;
  children: React.ReactNode;
}) {
  return (
    <label className="block">
      <span className="text-foreground text-sm font-medium">{label}</span>
      <div className="mt-1.5">{children}</div>
      {hint ? <p className="text-muted-foreground mt-1 text-xs">{hint}</p> : null}
    </label>
  );
}

/** Shared input styling for admin forms (matches the site's hand-rolled inputs). */
export const adminInputClass =
  "border-border bg-background text-foreground placeholder:text-muted-foreground focus-visible:ring-ring h-10 w-full rounded-lg border px-3 text-sm focus-visible:ring-2 focus-visible:outline-none";
