import { Skeleton } from "@/components/ui/states";

// Mirrors settings/page.tsx: title then a single settings card.
export default function Loading() {
  return (
    <div className="max-w-2xl">
      <Skeleton className="mb-5 h-8 w-40" />
      <Skeleton className="h-72 w-full rounded-xl" />
    </div>
  );
}
