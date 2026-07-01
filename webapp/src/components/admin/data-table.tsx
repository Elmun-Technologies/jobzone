import { EmptyState } from "@/components/ui/states";
import { adminStrings } from "@/lib/admin/strings";

export interface Column<T> {
  key: string;
  header: string;
  className?: string;
  render: (row: T) => React.ReactNode;
}

/**
 * Server-rendered admin table. Column defs keep pages declarative; rows are
 * whatever the admin data layer returned. Empty lists collapse to EmptyState.
 */
export function DataTable<T>({
  columns,
  rows,
  rowKey,
  emptyTitle = adminStrings.empty,
}: {
  columns: Column<T>[];
  rows: T[];
  rowKey: (row: T) => string;
  emptyTitle?: string;
}) {
  if (rows.length === 0) return <EmptyState title={emptyTitle} />;
  return (
    <div className="border-border overflow-x-auto rounded-xl border">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-border bg-muted/50 border-b text-left">
            {columns.map((col) => (
              <th
                key={col.key}
                className={`text-muted-foreground px-4 py-3 text-xs font-semibold tracking-wide uppercase ${col.className ?? ""}`}
              >
                {col.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={rowKey(row)} className="border-border border-b last:border-b-0">
              {columns.map((col) => (
                <td key={col.key} className={`px-4 py-3 align-top ${col.className ?? ""}`}>
                  {col.render(row)}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
