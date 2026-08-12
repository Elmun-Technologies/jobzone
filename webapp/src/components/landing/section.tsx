import type { ReactNode } from "react";

import { cn } from "@/lib/utils";

/**
 * Shared presentational primitives for the map-centric landing surface
 * (the home page). Kept dumb + server-rendered.
 */

/** Small volt-tinted mono label that sits above a section heading. */
export function Eyebrow({ children }: { children: ReactNode }) {
  return (
    <span className="text-foreground font-mono text-xs font-semibold tracking-wider uppercase">
      {children}
    </span>
  );
}

/** Centered eyebrow + heading (+ optional lead paragraph) for a section. */
export function SectionHead({
  eyebrow,
  title,
  body,
  className,
}: {
  eyebrow: string;
  title: string;
  body?: string;
  className?: string;
}) {
  return (
    <div className={cn("mx-auto max-w-2xl text-center", className)}>
      <Eyebrow>{eyebrow}</Eyebrow>
      <h2 className="text-foreground mt-3 text-3xl font-bold tracking-tight sm:text-4xl">
        {title}
      </h2>
      {body ? (
        <p className="text-muted-foreground mt-4 text-pretty">{body}</p>
      ) : null}
    </div>
  );
}
