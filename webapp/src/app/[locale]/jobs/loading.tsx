import { Container } from "@/components/ui/container";
import { Skeleton } from "@/components/ui/states";

/**
 * Route-level skeleton for /jobs. Rendered instantly while the RSC on
 * page.tsx awaits its four Supabase queries — so the seeker never sees
 * a black screen (the biggest FCP regression on prod). Matches the real
 * page's shape: filters column on the right, results list on the left,
 * title/count block on top. Keep the tag/heading rhythm aligned with
 * page.tsx or the swap-in will jump.
 */
export default function Loading() {
  return (
    <Container className="py-8">
      <div className="grid gap-6 lg:grid-cols-[1fr_320px]">
        <aside className="lg:col-start-2 lg:row-start-1">
          <div className="border-border bg-card rounded-2xl border p-4">
            <Skeleton className="h-5 w-24" />
            <div className="mt-4 space-y-3">
              {Array.from({ length: 5 }).map((_, i) => (
                <Skeleton key={i} className="h-10 w-full" />
              ))}
            </div>
          </div>
        </aside>
        <main className="min-w-0 lg:col-start-1 lg:row-start-1">
          <div className="mb-4">
            <Skeleton className="h-7 w-40 sm:h-8" />
            <Skeleton className="mt-1.5 h-4 w-24" />
          </div>
          <div className="mb-4 flex items-center gap-2">
            <Skeleton className="h-9 w-32 rounded-full" />
            <Skeleton className="h-9 w-20 rounded-full" />
          </div>
          <ul className="space-y-3">
            {Array.from({ length: 6 }).map((_, i) => (
              <li
                key={i}
                className="border-border bg-card flex gap-3 rounded-2xl border p-4"
              >
                <Skeleton className="size-12 shrink-0 rounded-xl" />
                <div className="min-w-0 flex-1 space-y-2">
                  <Skeleton className="h-5 w-2/3" />
                  <Skeleton className="h-4 w-1/3" />
                  <div className="flex gap-2 pt-1">
                    <Skeleton className="h-6 w-16 rounded-full" />
                    <Skeleton className="h-6 w-20 rounded-full" />
                  </div>
                </div>
              </li>
            ))}
          </ul>
        </main>
      </div>
    </Container>
  );
}
