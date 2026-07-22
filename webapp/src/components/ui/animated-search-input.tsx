"use client";

import { useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";

function useRotatingIndex(length: number, intervalMs: number) {
  const [index, setIndex] = useState(0);
  useEffect(() => {
    if (length <= 1) return;
    const id = setInterval(
      () => setIndex((i) => (i + 1) % length),
      intervalMs,
    );
    return () => clearInterval(id);
  }, [length, intervalMs]);
  return index;
}

/**
 * A search `<input>` whose empty-state placeholder cycles through example
 * queries ("Marketolog" → "Sotuvchi" → …) instead of sitting static, so the
 * bar never reads as an empty dead end. On focus it also drops a real,
 * clickable suggestion list (filtered by whatever's typed) from the same
 * `examples` — so the rotating word isn't just decorative copy, it's
 * discoverable as an actual one-tap search. Picking a suggestion fills the
 * field and submits the enclosing `<form>` immediately.
 *
 * The dropdown is portaled to `document.body` and positioned from the
 * enclosing `<form>`'s `getBoundingClientRect()` (both call sites wrap the
 * input in one) rather than the input's own — the hero form stacks the
 * input above its city-select + submit button below `sm:`, so anchoring to
 * the input alone would drop the list right on top of that row instead of
 * below the whole bar. The hero card also uses `overflow-hidden` to clip
 * its decorative backdrop glow, which would clip an in-flow dropdown too;
 * the portal sidesteps that regardless of which rect it's anchored to.
 */
export function AnimatedSearchInput({
  name,
  defaultValue = "",
  examples,
  ariaLabel,
  className,
}: {
  name: string;
  defaultValue?: string;
  examples: string[];
  ariaLabel: string;
  className?: string;
}) {
  const [value, setValue] = useState(defaultValue);
  const [focused, setFocused] = useState(false);
  const [rect, setRect] = useState<{
    top: number;
    left: number;
    width: number;
  } | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const index = useRotatingIndex(examples.length, 2600);
  const showRotating = examples.length > 0 && !focused && value.length === 0;

  const query = value.trim().toLowerCase();
  const suggestions = examples
    .filter((e) => e.toLowerCase().includes(query))
    .slice(0, 6);
  const showSuggestions = focused && suggestions.length > 0;

  // Reposition on open, and while open (scroll/resize can move the input
  // under a fixed-position portal without moving the input's own DOM node).
  useEffect(() => {
    if (!showSuggestions) return;
    const measure = () => {
      const el = inputRef.current?.form ?? inputRef.current;
      const r = el?.getBoundingClientRect();
      if (r) setRect({ top: r.bottom, left: r.left, width: r.width });
    };
    measure();
    window.addEventListener("scroll", measure, true);
    window.addEventListener("resize", measure);
    return () => {
      window.removeEventListener("scroll", measure, true);
      window.removeEventListener("resize", measure);
    };
  }, [showSuggestions]);

  function pick(example: string) {
    setValue(example);
    setFocused(false);
    // Defer past the blur/focus churn so the form has the new value when it
    // reads FormData (the toolbar's onSubmit) or serializes for a native GET.
    requestAnimationFrame(() => inputRef.current?.form?.requestSubmit());
  }

  return (
    <div className="relative min-w-0 flex-1">
      <input
        ref={inputRef}
        type="text"
        name={name}
        value={value}
        onChange={(e) => setValue(e.target.value)}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
        onKeyDown={(e) => {
          if (e.key === "Escape") setFocused(false);
        }}
        aria-label={ariaLabel}
        placeholder={showRotating ? "" : ariaLabel}
        autoComplete="off"
        className={className}
      />
      {showRotating ? (
        <span
          key={index}
          aria-hidden
          className="text-muted-foreground animate-placeholder-cycle pointer-events-none absolute inset-0 flex items-center truncate px-1"
        >
          {examples[index]}
        </span>
      ) : null}
      {showSuggestions && rect
        ? createPortal(
            <ul
              role="listbox"
              style={{ top: rect.top + 8, left: rect.left, width: rect.width }}
              className="border-border bg-card fixed z-[100] overflow-hidden rounded-2xl border py-1.5 shadow-xl"
            >
              {suggestions.map((s) => (
                <li key={s}>
                  <button
                    type="button"
                    role="option"
                    aria-selected={s === value}
                    // mousedown (not click) fires before the input's blur, so
                    // the field never loses focus/closes the list first.
                    onMouseDown={(e) => {
                      e.preventDefault();
                      pick(s);
                    }}
                    className="text-foreground hover:bg-muted block w-full px-4 py-2.5 text-left text-sm"
                  >
                    {s}
                  </button>
                </li>
              ))}
            </ul>,
            document.body,
          )
        : null}
    </div>
  );
}
