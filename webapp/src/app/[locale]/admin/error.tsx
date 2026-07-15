"use client";

import { buttonVariants } from "@/components/ui/button";
import { ErrorState } from "@/components/ui/states";
import { adminStrings } from "@/lib/admin/strings";
import { cn } from "@/lib/utils";

/** Defense-in-depth error boundary for the admin subtree — a thrown render
 * error (e.g. a bad admin data read) shows a retry instead of the default
 * Next.js error overlay. */
export default function AdminError({ reset }: { error: Error; reset: () => void }) {
  return (
    <ErrorState
      title={adminStrings.loadError}
      description={adminStrings.loadErrorHint}
      action={
        <button
          type="button"
          onClick={reset}
          className={cn(buttonVariants({ variant: "primary", size: "md" }))}
        >
          {adminStrings.retry}
        </button>
      }
    />
  );
}
