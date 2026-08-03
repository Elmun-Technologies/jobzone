"use client";

import { useState } from "react";

import { formatNational, nationalDigits, toE164 } from "@/lib/uz-phone";
import { cn } from "@/lib/utils";

/**
 * Phone field with the +998 pinned in place, the way every local app asks for
 * a number here.
 *
 * The visitor types the nine national digits and nothing else: no country code
 * to remember, no punctuation to get wrong, a numeric keypad on a phone, and
 * grouping applied as they go. What leaves the field is always E.164
 * ("+998901234567") or "" — so the stored value is dialable from a Telegram
 * notification without a human repairing it first.
 *
 * Controlled (`value`/`onChange`, E.164) or form-shaped (`name`, submitting
 * E.164 through a hidden input, seeded from `defaultValue`).
 */
export function UzPhoneInput({
  value,
  onChange,
  name,
  defaultValue = "",
  id,
  required,
  className,
  "aria-label": ariaLabel,
}: {
  /** E.164 ("+998901234567") or "". */
  value?: string;
  onChange?: (e164: string) => void;
  name?: string;
  defaultValue?: string;
  id?: string;
  required?: boolean;
  className?: string;
  "aria-label"?: string;
}) {
  // The digits live here even in controlled mode, and that is the whole trick:
  // what we hand the parent is E.164, which is "" until all nine digits are in,
  // so rendering from the parent's value would throw away every keystroke but
  // the last and the field could never be typed into at all.
  const [digits, setDigits] = useState(() =>
    nationalDigits(value ?? defaultValue),
  );

  // Adopt a number the parent set behind our back — a résumé restored from the
  // sign-in stash, or a profile prefilled from the server. Only when it is
  // non-empty: mid-typing the parent holds "" (incomplete), and treating that
  // as an external change would wipe the field on every backspace.
  const external = value === undefined ? "" : nationalDigits(value);
  if (external && external !== digits) setDigits(external);

  function set(next: string) {
    const d = nationalDigits(next);
    setDigits(d);
    onChange?.(toE164(d));
  }

  return (
    <div
      className={cn(
        "border-border bg-background focus-within:ring-ring flex h-11 w-full items-center rounded-lg border focus-within:ring-2",
        className,
      )}
    >
      <span className="text-muted-foreground shrink-0 pr-1 pl-3 text-sm tabular-nums">
        +998
      </span>
      <input
        id={id}
        type="tel"
        inputMode="numeric"
        autoComplete="tel-national"
        required={required}
        aria-label={ariaLabel}
        // Not the E.164 value: the visitor reads and edits the national part,
        // grouped. `maxLength` counts the spaces the grouping adds.
        value={formatNational(digits)}
        onChange={(e) => set(e.target.value)}
        placeholder="90 123 45 67"
        maxLength={12}
        className="text-foreground placeholder:text-muted-foreground h-full w-full bg-transparent pr-3 text-sm outline-none"
      />
      {name ? <input type="hidden" name={name} value={toE164(digits)} /> : null}
    </div>
  );
}
