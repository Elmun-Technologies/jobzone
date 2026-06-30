"use client";

import { useSyncExternalStore } from "react";

// A single shared clock for all subscribers (one interval, not one per card).
// `now` stays 0 until the first subscriber mounts, so SSR + the first paint
// render `null` — relative times only appear on the client, avoiding any
// hydration mismatch from differing server/client wall-clocks.
let now = 0;
const listeners = new Set<() => void>();
let timer: ReturnType<typeof setInterval> | null = null;

function subscribe(callback: () => void): () => void {
  if (now === 0) now = Date.now();
  listeners.add(callback);
  if (timer == null) {
    timer = setInterval(() => {
      now = Date.now();
      for (const l of listeners) l();
    }, 60_000);
  }
  return () => {
    listeners.delete(callback);
    if (listeners.size === 0 && timer != null) {
      clearInterval(timer);
      timer = null;
    }
  };
}

function getSnapshot(): number | null {
  return now === 0 ? null : now;
}

function getServerSnapshot(): number | null {
  return null;
}

/**
 * Current epoch milliseconds, refreshed each minute. `null` during SSR and the
 * first client render, so callers should treat `null` as "time not ready yet".
 */
export function useNow(): number | null {
  return useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot);
}
