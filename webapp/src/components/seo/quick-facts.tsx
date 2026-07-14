import { formatDate } from "@/lib/format";

/**
 * "At a glance" fact strip — 3-4 short data points that both a human
 * skims and an LLM extracts verbatim. Rendered as a small ordered grid
 * of dt/dd pairs (semantic, and both AI parsers and screen readers
 * treat this as a definition list).
 *
 * Numbers matter here: GEO writeups consistently note that models cite
 * pages with concrete stats ("N open vacancies in {city}, salary
 * {low}–{high} so'm") over pages with generic marketing copy. Every
 * value passed in should be a concrete figure, not a placeholder.
 */
export function QuickFacts({
  label,
  items,
  updatedIso,
  updatedLabel,
}: {
  /** Section aria-label / small caption above the strip. */
  label: string;
  items: { label: string; value: string }[];
  /** Latest job postedAt ISO date — rendered as "Updated: DD.MM.YYYY".
   * Omit if there's no signal (empty landing, freshness would mislead). */
  updatedIso?: string | null;
  updatedLabel: string;
}) {
  return (
    <aside
      aria-label={label}
      className="border-border bg-muted/30 mt-6 rounded-xl border p-4"
    >
      <dl className="grid grid-cols-2 gap-x-6 gap-y-3 text-sm sm:grid-cols-4">
        {items.map((it) => (
          <div key={it.label} className="flex flex-col">
            <dt className="text-muted-foreground text-xs uppercase tracking-wide">
              {it.label}
            </dt>
            <dd className="text-foreground mt-0.5 font-mono text-base font-semibold">
              {it.value}
            </dd>
          </div>
        ))}
      </dl>
      {updatedIso ? (
        <p className="text-muted-foreground mt-3 text-xs">
          {updatedLabel}: <time dateTime={updatedIso}>{formatDate(updatedIso)}</time>
        </p>
      ) : null}
    </aside>
  );
}
