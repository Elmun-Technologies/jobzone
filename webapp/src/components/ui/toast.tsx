"use client";

import { X } from "lucide-react";
import { useTranslations } from "next-intl";
import { useSyncExternalStore } from "react";

import { cn } from "@/lib/utils";

/**
 * Toasts — transient popups, imperative API.
 *
 * A module-level store rather than React context on purpose: `toast()` is
 * called from event handlers and realtime callbacks all over the tree, and a
 * context would force every caller to sit under a provider. `<Toaster />` is
 * mounted once in the locale layout and subscribes to the store; anything can
 * push without knowing where the container lives.
 *
 * No dependency (no sonner/Radix) — the whole thing is ~120 lines and this
 * keeps the client bundle flat.
 */

export type ToastVariant = "default" | "success" | "error";

export interface ToastInput {
  title: string;
  description?: string | null;
  /** Locale-relative path; makes the whole toast a link. */
  href?: string | null;
  /** Label for the link affordance, e.g. "Ko'rish". */
  actionLabel?: string;
  variant?: ToastVariant;
  /** Auto-dismiss delay in ms; 0 keeps it until dismissed. */
  duration?: number;
}

export interface ToastItem extends ToastInput {
  id: string;
}

const DEFAULT_DURATION = 6000;
/** Older toasts drop off the top rather than growing a wall of cards. */
const MAX_VISIBLE = 3;

let items: ToastItem[] = [];
const listeners = new Set<() => void>();
let counter = 0;

function notify() {
  for (const l of listeners) l();
}

function subscribe(listener: () => void) {
  listeners.add(listener);
  return () => {
    listeners.delete(listener);
  };
}

function getSnapshot() {
  return items;
}

/** Stable empty array: a new reference each call would loop the SSR render. */
const SERVER_SNAPSHOT: ToastItem[] = [];
function getServerSnapshot() {
  return SERVER_SNAPSHOT;
}

export function dismissToast(id: string) {
  const next = items.filter((t) => t.id !== id);
  if (next.length === items.length) return;
  items = next;
  notify();
}

/** Show a toast. Returns its id so callers can dismiss it early. */
export function toast(input: ToastInput): string {
  const id = `t${++counter}`;
  items = [...items, { ...input, id }].slice(-MAX_VISIBLE);
  notify();
  const duration = input.duration ?? DEFAULT_DURATION;
  if (duration > 0 && typeof window !== "undefined") {
    window.setTimeout(() => dismissToast(id), duration);
  }
  return id;
}

const VARIANT: Record<ToastVariant, string> = {
  default: "border-border",
  success: "border-primary/40",
  error: "border-destructive/40",
};

/**
 * The toast container. Mount once. Bottom-anchored on phones (thumb reach,
 * clear of the header) and top-right from `sm:` up.
 */
export function Toaster() {
  const t = useTranslations("common");
  const list = useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot);
  if (list.length === 0) return null;

  return (
    <div
      // `polite`: a job match or a new message shouldn't interrupt a screen
      // reader mid-sentence.
      aria-live="polite"
      aria-atomic={false}
      className="pointer-events-none fixed inset-x-3 bottom-3 z-100 flex flex-col gap-2 sm:inset-x-auto sm:top-20 sm:right-4 sm:bottom-auto sm:w-[22rem]"
    >
      {list.map((item) => (
        <ToastCard key={item.id} item={item} closeLabel={t("close")} />
      ))}
    </div>
  );
}

function ToastCard({
  item,
  closeLabel,
}: {
  item: ToastItem;
  closeLabel: string;
}) {
  return (
    <div
      role="status"
      className={cn(
        "bg-card toast-in pointer-events-auto flex items-start gap-3 rounded-2xl border p-3 shadow-lg",
        VARIANT[item.variant ?? "default"],
      )}
    >
      <div className="min-w-0 flex-1">
        <p className="text-foreground text-sm font-semibold">{item.title}</p>
        {item.description ? (
          <p className="text-muted-foreground mt-0.5 line-clamp-2 text-sm">
            {item.description}
          </p>
        ) : null}
        {item.href && item.actionLabel ? (
          <a
            href={item.href}
            onClick={() => dismissToast(item.id)}
            className="text-primary-ink mt-2 inline-block text-sm font-semibold hover:underline"
          >
            {item.actionLabel}
          </a>
        ) : null}
      </div>
      <button
        type="button"
        onClick={() => dismissToast(item.id)}
        aria-label={closeLabel}
        className="text-muted-foreground hover:text-foreground -m-1 shrink-0 p-1 transition-colors"
      >
        <X className="size-4" />
      </button>
    </div>
  );
}
