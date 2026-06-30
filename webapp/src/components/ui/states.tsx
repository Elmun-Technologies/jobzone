import { Loader2 } from "lucide-react";
import * as React from "react";

import { cn } from "@/lib/utils";

/** Centered spinner for loading states. */
export function Spinner({ className }: { className?: string }) {
  return (
    <div className="flex w-full items-center justify-center py-16">
      <Loader2
        className={cn("text-muted-foreground size-6 animate-spin", className)}
        aria-hidden
      />
      <span className="sr-only">Loading</span>
    </div>
  );
}

/** Shimmer placeholder block. */
export function Skeleton({
  className,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn("bg-muted animate-pulse rounded-md", className)}
      {...props}
    />
  );
}

function StateMessage({
  icon,
  title,
  description,
  action,
}: {
  icon?: React.ReactNode;
  title: string;
  description?: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 py-16 text-center">
      {icon ? <div className="text-muted-foreground">{icon}</div> : null}
      <p className="text-foreground text-base font-semibold">{title}</p>
      {description ? (
        <p className="text-muted-foreground max-w-sm text-sm">{description}</p>
      ) : null}
      {action}
    </div>
  );
}

/** Empty-list placeholder. */
export function EmptyState(props: {
  icon?: React.ReactNode;
  title: string;
  description?: string;
}) {
  return <StateMessage {...props} />;
}

/** Error placeholder with an optional retry action. */
export function ErrorState(props: {
  title: string;
  description?: string;
  action?: React.ReactNode;
}) {
  return <StateMessage {...props} />;
}
