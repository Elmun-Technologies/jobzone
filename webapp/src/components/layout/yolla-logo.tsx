import { cn } from "@/lib/utils";

const ANTON = "var(--font-anton), system-ui, sans-serif";

/**
 * Yolla brand lockup: the volt "yo" speech-bubble mark + the "yolla" wordmark
 * (Anton). The volt bubble + ink "yo" reads on both light and dark surfaces;
 * the wordmark uses the theme foreground.
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
          fill="#c7fb00"
          d="M10 2h24a8 8 0 0 1 8 8v16a8 8 0 0 1-8 8H19l-9 9 1.2-9H10a8 8 0 0 1-8-8V10a8 8 0 0 1 8-8Z"
        />
        <text
          x="22"
          y="20"
          textAnchor="middle"
          dominantBaseline="central"
          fill="#0a0a0a"
          style={{ fontFamily: ANTON, fontWeight: 700, fontSize: "17px" }}
        >
          yo
        </text>
      </svg>
      {withWordmark ? (
        <span
          className="text-foreground text-2xl leading-none"
          style={{ fontFamily: ANTON }}
        >
          yolla
        </span>
      ) : null}
    </span>
  );
}
