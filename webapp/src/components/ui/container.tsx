import * as React from "react";

import { cn } from "@/lib/utils";

/**
 * Centered, max-width page container. Caps content width on desktop so wide
 * monitors don't stretch the layout edge-to-edge.
 */
export function Container({
  className,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn("mx-auto w-full max-w-6xl px-4 sm:px-6 lg:px-8", className)}
      {...props}
    />
  );
}
