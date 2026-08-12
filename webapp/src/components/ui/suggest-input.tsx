"use client";

import { useEffect, useId, useMemo, useRef, useState } from "react";

import { cn } from "@/lib/utils";

/**
 * A text field that offers matching suggestions as you type, and still takes
 * free text.
 *
 * Replaces `<input list=…>` + `<datalist>`: the native control is invisible on
 * iOS Safari (which is most of this market's traffic — the mobile web is the
 * product's front door) and, where it does render, it is an OS popup that
 * ignores every brand token and the current theme. This is the same
 * type-and-pick interaction the local job apps use on the title field, drawn
 * with our own tokens, keyboard-navigable, and identical on every browser.
 *
 * Controlled (`value` + `onValueChange`) or uncontrolled (`defaultValue`, read
 * back through `name` in FormData). Suggestions only appear after the visitor
 * types — never on focus of a prefilled field, which would otherwise cover the
 * fields below the moment an edit form is opened.
 */
export function SuggestInput({
  suggest,
  value,
  defaultValue = "",
  onValueChange,
  onPick,
  onSubmitValue,
  onBlur,
  name,
  id,
  placeholder,
  className,
  required,
  "aria-label": ariaLabel,
}: {
  /** Returns the suggestions for the current text (already limited/ranked). */
  suggest: (query: string) => string[];
  value?: string;
  defaultValue?: string;
  onValueChange?: (value: string) => void;
  /** Fired only when a suggestion is chosen from the list — not on typing, so
   * a caller can tell "they picked Sotuvchi" from "they have typed as far as
   * S-o-t-u-v-c-h-i and may keep going". */
  onPick?: (value: string) => void;
  /** Enter with no suggestion highlighted: commit whatever is typed. Gives the
   * field a keyboard equivalent of the picker for a title we don't list. */
  onSubmitValue?: (value: string) => void;
  /** Leaving the field with text in it. Selecting a suggestion does not blur
   * (the list swallows the pointerdown), so this only sees text the visitor
   * typed and walked away from. */
  onBlur?: (value: string) => void;
  name?: string;
  id?: string;
  placeholder?: string;
  className?: string;
  required?: boolean;
  "aria-label"?: string;
}) {
  const [inner, setInner] = useState(defaultValue);
  const current = value ?? inner;
  // Suggestions stay closed until the field is actually typed in — see above.
  const [typing, setTyping] = useState(false);
  const [active, setActive] = useState(-1);
  const listId = useId();
  const wrapRef = useRef<HTMLDivElement>(null);

  const items = useMemo(
    () => (typing ? suggest(current) : []),
    [typing, current, suggest],
  );
  const open = typing && items.length > 0;

  // Dismiss when the visitor taps anywhere else. `pointerdown` (not `click`)
  // so the list is gone before the tap lands on whatever is underneath it.
  useEffect(() => {
    if (!open) return;
    const onDown = (e: PointerEvent) => {
      if (!wrapRef.current?.contains(e.target as Node)) setTyping(false);
    };
    document.addEventListener("pointerdown", onDown);
    return () => document.removeEventListener("pointerdown", onDown);
  }, [open]);

  function commit(next: string) {
    if (value === undefined) setInner(next);
    onValueChange?.(next);
  }

  function pick(label: string) {
    commit(label);
    setTyping(false);
    setActive(-1);
    onPick?.(label);
  }

  function onKeyDown(e: React.KeyboardEvent<HTMLInputElement>) {
    if (e.key === "Escape") {
      setTyping(false);
      setActive(-1);
      return;
    }
    if (e.key === "Enter") {
      // Enter selects the highlighted suggestion. With nothing highlighted it
      // commits what was typed if the caller takes free text; otherwise it
      // falls through, so the wizard's "next" button keeps working from the
      // keyboard and free text is never overwritten by a guess.
      if (open && active >= 0) {
        e.preventDefault();
        pick(items[active]);
      } else if (onSubmitValue && current.trim() !== "") {
        e.preventDefault();
        setTyping(false);
        setActive(-1);
        onSubmitValue(current.trim());
      }
      return;
    }
    if (!open) return;
    if (e.key === "ArrowDown" || e.key === "ArrowUp") {
      e.preventDefault();
      const step = e.key === "ArrowDown" ? 1 : -1;
      setActive((i) => (i + step + items.length) % items.length);
    }
  }

  return (
    <div ref={wrapRef} className="relative">
      <input
        id={id}
        name={name}
        value={current}
        placeholder={placeholder}
        required={required}
        aria-label={ariaLabel}
        autoComplete="off"
        role="combobox"
        aria-expanded={open}
        aria-controls={open ? listId : undefined}
        aria-autocomplete="list"
        aria-activedescendant={
          open && active >= 0 ? `${listId}-${active}` : undefined
        }
        onChange={(e) => {
          setTyping(true);
          setActive(-1);
          commit(e.target.value);
        }}
        onKeyDown={onKeyDown}
        onBlur={() => {
          setTyping(false);
          setActive(-1);
          if (current.trim() !== "") onBlur?.(current.trim());
        }}
        className={className}
      />
      {open ? (
        <ul
          id={listId}
          role="listbox"
          className="border-border bg-background absolute inset-x-0 top-full z-30 mt-1 max-h-64 overflow-y-auto rounded-xl border py-1 shadow-lg"
        >
          {items.map((label, i) => (
            <li key={label}>
              <button
                id={`${listId}-${i}`}
                type="button"
                role="option"
                aria-selected={i === active}
                // Selection happens on pointerdown, not click.
                //
                // Two things go wrong otherwise, and they pull in opposite
                // directions: without `preventDefault` the input blurs first,
                // the list unmounts under the finger, and the tap lands on
                // whatever is now underneath; WITH it on a touch screen, the
                // browser suppresses the synthesized `click` entirely, so a
                // phone tap selected nothing at all (keyboard still worked,
                // which is what made it easy to miss). Doing the work in
                // pointerdown — before either blur or click — is the one
                // ordering that holds for mouse, touch and pen alike.
                onPointerDown={(e) => {
                  e.preventDefault();
                  pick(label);
                }}
                onMouseEnter={() => setActive(i)}
                className={cn(
                  "block w-full px-4 py-2.5 text-left text-sm transition-colors",
                  i === active
                    ? "bg-accent text-accent-foreground"
                    : "text-foreground",
                )}
              >
                {label}
              </button>
            </li>
          ))}
        </ul>
      ) : null}
    </div>
  );
}
