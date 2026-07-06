import type { ReactNode } from "react";

import { cn } from "@/lib/utils";

/**
 * Shared presentational primitives for the map-centric landing surfaces
 * (`/about` and the home page). Kept dumb + server-rendered so both pages
 * reuse the exact same visual language without duplication.
 */

/** Small volt-tinted mono label that sits above a section heading. */
export function Eyebrow({ children }: { children: ReactNode }) {
  return (
    <span className="text-primary font-mono text-xs font-semibold tracking-wider uppercase">
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

/**
 * Employer reputation chip — score + name + flower/fly marks. Used in the
 * `/about` reputation section and the home "obro'" teaser.
 */
export function RatingCard({
  name,
  caption,
  score,
  marks,
  good,
}: {
  name: string;
  caption: string;
  score: string;
  marks: string;
  good?: boolean;
}) {
  return (
    <div className="border-border bg-card flex items-center gap-4 rounded-2xl border p-4">
      <div
        className={cn(
          "flex size-12 shrink-0 items-center justify-center rounded-xl font-mono text-lg font-bold",
          good
            ? "bg-primary/15 text-foreground"
            : "bg-muted text-muted-foreground",
        )}
      >
        {score}
      </div>
      <div className="min-w-0">
        <p className="text-foreground font-semibold">{name}</p>
        <p className="text-muted-foreground text-xs">{caption}</p>
      </div>
      <span className="ml-auto text-lg" aria-hidden>
        {marks}
      </span>
    </div>
  );
}
