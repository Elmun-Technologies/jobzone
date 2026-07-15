import { Skeleton } from "@/components/ui/states";

/** Loading placeholder matching DataTable's chrome (border-border rounded-xl
 * border, muted header row) — used by admin loading.tsx files so list pages
 * don't flash a bare blank panel while the server read resolves. */
export function TableSkeleton({
  rows = 6,
  columns = 4,
}: {
  rows?: number;
  columns?: number;
}) {
  return (
    <div className="border-border overflow-x-auto rounded-xl border">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-border bg-muted/50 border-b">
            {Array.from({ length: columns }).map((_, i) => (
              <th key={i} className="px-4 py-3">
                <Skeleton className="h-3 w-16" />
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {Array.from({ length: rows }).map((_, i) => (
            <tr key={i} className="border-border border-b last:border-b-0">
              {Array.from({ length: columns }).map((_, j) => (
                <td key={j} className="px-4 py-3">
                  <Skeleton className="h-4 w-full max-w-32" />
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

/** Title bar + search input placeholder matching the `h1` + `SearchInput`
 * header row every list page renders above its table. */
export function AdminListSkeleton({
  rows = 6,
  columns = 4,
  withSearch = true,
}: {
  rows?: number;
  columns?: number;
  withSearch?: boolean;
}) {
  return (
    <div>
      <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
        <Skeleton className="h-8 w-40" />
        {withSearch ? <Skeleton className="h-9 w-56" /> : null}
      </div>
      <TableSkeleton rows={rows} columns={columns} />
    </div>
  );
}
