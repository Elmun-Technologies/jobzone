import { Skeleton } from "@/components/ui/states";

// Mirrors broadcast/page.tsx: title, reach summary cards, then the form.
export default function Loading() {
  return (
    <div className="max-w-2xl">
      <Skeleton className="mb-1 h-8 w-48" />
      <Skeleton className="mb-5 h-4 w-80" />
      <div className="mb-6 grid grid-cols-3 gap-3">
        {Array.from({ length: 3 }).map((_, i) => (
          <Skeleton key={i} className="h-20 w-full rounded-xl" />
        ))}
      </div>
      <Skeleton className="h-64 w-full rounded-xl" />
    </div>
  );
}
