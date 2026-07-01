import { cn } from "@/lib/utils";

export type BadgeTone = "ok" | "warn" | "muted" | "destructive";

const TONES: Record<BadgeTone, string> = {
  ok: "bg-[#c7fb00] text-[#0a0a0a]",
  warn: "bg-amber-100 text-amber-900 dark:bg-amber-900/40 dark:text-amber-200",
  muted: "bg-muted text-muted-foreground",
  destructive: "bg-destructive/10 text-destructive",
};

/** Small state pill (status/verification/moderation) for admin tables. */
export function StatusBadge({
  tone,
  children,
}: {
  tone: BadgeTone;
  children: React.ReactNode;
}) {
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold whitespace-nowrap",
        TONES[tone],
      )}
    >
      {children}
    </span>
  );
}
