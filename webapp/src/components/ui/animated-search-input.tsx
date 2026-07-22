"use client";

import { useEffect, useState } from "react";

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
 * bar never reads as an empty dead end. `ariaLabel` stays the real a11y
 * label and becomes the plain placeholder once focused/typed into — the
 * rotating word is decorative only (aria-hidden) and pauses whenever there's
 * a real value or the field has focus.
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
  const index = useRotatingIndex(examples.length, 2600);
  const showRotating = examples.length > 0 && !focused && value.length === 0;

  return (
    <div className="relative min-w-0 flex-1">
      <input
        type="text"
        name={name}
        value={value}
        onChange={(e) => setValue(e.target.value)}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
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
    </div>
  );
}
