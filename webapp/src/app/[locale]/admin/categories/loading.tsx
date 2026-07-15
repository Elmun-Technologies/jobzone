import { Skeleton } from "@/components/ui/states";
import { AdminListSkeleton } from "@/components/admin/table-skeleton";

// Mirrors categories/page.tsx: a "new category" form card above the table.
export default function Loading() {
  return (
    <div>
      <Skeleton className="mb-5 h-8 w-40" />
      <Skeleton className="mb-6 h-40 w-full rounded-xl" />
      <AdminListSkeleton withSearch={false} columns={5} />
    </div>
  );
}
