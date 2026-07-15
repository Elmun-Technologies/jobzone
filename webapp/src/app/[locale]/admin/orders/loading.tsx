import { Skeleton } from "@/components/ui/states";
import { AdminListSkeleton } from "@/components/admin/table-skeleton";

// Mirrors orders/page.tsx: the order list table plus the product-pricing
// table beneath it.
export default function Loading() {
  return (
    <div>
      <AdminListSkeleton />
      <div className="mt-10">
        <Skeleton className="mb-3 h-6 w-48" />
        <AdminListSkeleton withSearch={false} rows={4} />
      </div>
    </div>
  );
}
