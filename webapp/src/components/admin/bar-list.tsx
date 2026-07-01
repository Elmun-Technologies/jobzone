import { groupNumber } from "@/lib/format";

/**
 * Server-rendered horizontal bar list (top-10s, funnel stages): direct labels
 * left, grouped value right, a thin rounded bar scaled to the max underneath.
 * No client JS — magnitude comparison doesn't need a hover layer here.
 */
export function BarList({
  items,
}: {
  items: { label: string; value: number }[];
}) {
  const max = Math.max(1, ...items.map((i) => i.value));
  return (
    <ul className="space-y-3">
      {items.map((item) => (
        <li key={item.label}>
          <div className="flex items-baseline justify-between gap-3 text-sm">
            <span className="text-foreground truncate">{item.label}</span>
            <span className="text-muted-foreground font-mono text-xs tabular-nums">
              {groupNumber(item.value)}
            </span>
          </div>
          <div className="bg-muted mt-1 h-1.5 rounded-full">
            <div
              className="h-1.5 rounded-full bg-[var(--chart-series)]"
              style={{ width: `${Math.max(2, (item.value / max) * 100)}%` }}
            />
          </div>
        </li>
      ))}
    </ul>
  );
}
