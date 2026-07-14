// One source of truth for the volt salary-bubble pin used on every web map
// (landing showcase + /explore, Yandex and Leaflet engines alike). The bubble
// is the mockup's price tag: rounded volt pill on ink, mono type, a pointer
// tail on the exact location; a paid listing (brand/premium) gets the volt
// glow and premium additionally a ★ prefix.
//
// Everything is `display:inline-block` + `white-space:nowrap` on purpose: both
// engines drop the markup into a zero-width positioned wrapper, where a block
// element collapses to width 0 and `overflow:hidden` clips the pill into a
// tiny circle (the bug this module fixes). Inline-block with nowrap sizes to
// the full text even inside a 0×0 parent.
//
// `data-job-id` makes the pin addressable from plain DOM event delegation —
// hover (preview card) and click (open the job) are handled by the React
// wrapper around the map, identically for both engines, instead of through
// per-engine marker event APIs.

export type PinTier = "brand" | "premium" | null;

/** Escape raw employer text before it lands in pin/card HTML strings. */
export function escHtml(v: string): string {
  return v
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

/** The pin's drop shadow — a volt glow marks a paid (boosted) listing. */
export function pinShadow(tier: PinTier): string {
  return tier
    ? "0 0 0 2px rgba(199,251,0,.55),0 4px 16px rgba(199,251,0,.55)"
    : "0 4px 12px rgba(0,0,0,.35)";
}

/** Premium listings lead with a star; the label itself stays the salary. */
export function pinLabel(pill: string, tier: PinTier): string {
  return tier === "premium" ? `★ ${pill}` : pill;
}

/**
 * The bubble markup. Values are interpolated verbatim: Leaflet callers pass
 * escaped text (escHtml) and a literal shadow; Yandex callers pass
 * `$[properties.…]` tokens and let the template engine substitute (it
 * HTML-escapes property values itself).
 */
export function salaryPinMarkup(v: {
  pill: string;
  jobId: string;
  shadow: string;
}): string {
  // `.yolla-pin` (hover lift + pointer, globals.css) sits on the bubble, not
  // the root: the root's inline transform would beat the class's hover
  // transform, and the bubble is what should visibly lift.
  return `<div data-job-id="${v.jobId}" style="position:relative;display:inline-block;white-space:nowrap;transform:translate(-50%,-100%);will-change:transform;cursor:pointer">
    <span class="yolla-pin" style="display:inline-block;background:#C7FB00;color:#0A0A0A;border:2px solid #0A0A0A;border-radius:9999px;padding:5px 11px;font-weight:700;font-size:12.5px;line-height:1.15;font-family:ui-monospace,SFMono-Regular,Menlo,monospace;box-shadow:${v.shadow}">${v.pill}</span>
    <span style="position:absolute;left:50%;top:100%;transform:translate(-50%,-1px);width:0;height:0;border-left:6px solid transparent;border-right:6px solid transparent;border-top:7px solid #0A0A0A"></span>
  </div>`;
}

/**
 * Clickable hit-box for the Yandex `iconShape` option, matching the bubble's
 * box above the anchor point (without it the clusterer draws stray badges and
 * taps miss). Salary pills are short — ~110px covers "★ 12,5 mln" comfortably.
 */
export const SALARY_PIN_SHAPE = {
  type: "Rectangle" as const,
  coordinates: [
    [-55, -44],
    [55, 2],
  ],
};
