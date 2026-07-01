import { groupNumber } from "@/lib/format";

/**
 * KPI tile: a big grouped number over a muted label. Numbers wear Space Mono
 * (the brand's numeric face) with tabular figures so rows align.
 */
export function StatCard({
  label,
  value,
  hint,
}: {
  label: string;
  value: number;
  hint?: string;
}) {
  return (
    <div className="border-border bg-card rounded-xl border p-5">
      <p className="text-foreground font-mono text-2xl font-bold tabular-nums sm:text-3xl">
        {groupNumber(value)}
      </p>
      <p className="text-muted-foreground mt-1 text-sm">{label}</p>
      {hint ? <p className="text-muted-foreground mt-0.5 text-xs">{hint}</p> : null}
    </div>
  );
}
