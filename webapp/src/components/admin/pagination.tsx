import { buttonVariants } from "@/components/ui/button";
import { adminStrings } from "@/lib/admin/strings";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

/**
 * Prev/next pagination driven by the `page` search param, preserving the rest
 * of the query (search, filters). Pages are 1-based.
 */
export function Pagination({
  pathname,
  page,
  hasNext,
  query = {},
}: {
  pathname: string;
  page: number;
  hasNext: boolean;
  query?: Record<string, string>;
}) {
  if (page <= 1 && !hasNext) return null;
  const linkTo = (p: number) => ({
    pathname,
    query: { ...query, ...(p > 1 ? { page: String(p) } : {}) },
  });
  const disabled = "pointer-events-none opacity-40";
  return (
    <div className="mt-4 flex items-center justify-between gap-3">
      <Link
        href={linkTo(page - 1)}
        aria-disabled={page <= 1}
        className={cn(buttonVariants({ variant: "outline", size: "sm" }), page <= 1 && disabled)}
      >
        {adminStrings.prev}
      </Link>
      <span className="text-muted-foreground font-mono text-xs tabular-nums">{page}</span>
      <Link
        href={linkTo(page + 1)}
        aria-disabled={!hasNext}
        className={cn(buttonVariants({ variant: "outline", size: "sm" }), !hasNext && disabled)}
      >
        {adminStrings.next}
      </Link>
    </div>
  );
}
