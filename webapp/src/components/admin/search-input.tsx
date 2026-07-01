import { Search } from "lucide-react";

import { adminStrings } from "@/lib/admin/strings";

/**
 * GET search form: submits `?q=` to the current admin page (server components
 * re-render with the filtered list). Plain form — no client JS needed.
 */
export function SearchInput({
  defaultValue = "",
  placeholder = adminStrings.search,
}: {
  defaultValue?: string;
  placeholder?: string;
}) {
  return (
    <form method="get" className="relative w-full max-w-xs">
      <Search
        className="text-muted-foreground pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2"
        aria-hidden
      />
      <input
        type="search"
        name="q"
        defaultValue={defaultValue}
        placeholder={placeholder}
        className="border-border bg-background text-foreground placeholder:text-muted-foreground focus-visible:ring-ring h-10 w-full rounded-full border pr-4 pl-9 text-sm focus-visible:ring-2 focus-visible:outline-none"
      />
    </form>
  );
}
