import { cn } from "@/lib/utils";

/**
 * Yolla brand lockup: the "yo" speech-bubble mark + the "yolla" wordmark.
 * Per the brand board both the glyph and wordmark are Archivo 900 (not Anton).
 * The mark is theme-aware: ink bubble + volt "yo" on light, inverted on dark —
 * so it stays high-contrast on either surface. Wordmark uses the foreground.
 */
export function YollaLogo({
  withWordmark = true,
  className,
}: {
  withWordmark?: boolean;
  className?: string;
}) {
  return (
    <span className={cn("inline-flex items-center gap-2", className)}>
      <svg
        viewBox="0 0 44 48"
        className="size-7 shrink-0"
        role="img"
        aria-label="Yolla"
      >
        <path
          className="fill-[#0a0a0a] dark:fill-[#c7fb00]"
          d="M10 2h24a8 8 0 0 1 8 8v16a8 8 0 0 1-8 8H19l-9 9 1.2-9H10a8 8 0 0 1-8-8V10a8 8 0 0 1 8-8Z"
        />
        <text
          x="22"
          y="20"
          textAnchor="middle"
          dominantBaseline="central"
          className="fill-[#c7fb00] dark:fill-[#0a0a0a]"
          style={{
            fontWeight: 900,
            fontSize: "17px",
            letterSpacing: "-0.04em",
          }}
        >
          yo
        </text>
      </svg>
      {withWordmark ? (
        <span className="text-foreground text-2xl leading-none font-black tracking-[-0.05em]">
          yolla
        </span>
      ) : null}
    </span>
  );
}
