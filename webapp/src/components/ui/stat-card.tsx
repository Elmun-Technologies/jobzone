import { Link } from "@/i18n/navigation";
import { groupNumber } from "@/lib/format";

/**
 * KPI tile: a big grouped number over a muted label. Numbers wear Space Mono
 * (the brand's numeric face) with tabular figures so rows align. Pass `href`
 * to make the tile a link to wherever that number is explained (e.g. a
 * balance tile linking to the wallet).
 */
export function StatCard({
  label,
  value,
  hint,
  href,
}: {
  label: string;
  value: number;
  hint?: string;
  href?: string;
}) {
  const content = (
    <>
      <p className="text-foreground font-mono text-2xl font-bold tabular-nums sm:text-3xl">
        {groupNumber(value)}
      </p>
      <p className="text-muted-foreground mt-1 text-sm">{label}</p>
      {hint ? (
        <p className="text-muted-foreground mt-0.5 text-xs">{hint}</p>
      ) : null}
    </>
  );
  if (href) {
    return (
      <Link
        href={href}
        className="border-border bg-card hover:border-primary/40 block rounded-xl border p-5 transition-colors"
      >
        {content}
      </Link>
    );
  }
  return (
    <div className="border-border bg-card rounded-xl border p-5">{content}</div>
  );
}
