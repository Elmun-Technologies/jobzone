import L from "leaflet";

import {
  escHtml,
  pinLabel,
  pinShadow,
  salaryPinMarkup,
  type PinTier,
} from "./pin-markup";

const cache = new Map<string, L.DivIcon>();

/**
 * The shared volt salary-tag divIcon for the Leaflet engine, carrying
 * `data-job-id` for the hover-card/click delegation.
 *
 * Cached per (job, pill, tier) so the icon's identity is stable across
 * re-renders: react-leaflet replaces a marker's DOM element whenever the
 * `icon` prop changes identity, and swapping the element under the cursor
 * both flickers the pin and swallows its `mouseout` (the hover card would
 * never close).
 */
export function salaryPinIcon(
  pill: string,
  jobId: string,
  tier: PinTier,
): L.DivIcon {
  const key = `${jobId}|${pill}|${tier ?? ""}`;
  const hit = cache.get(key);
  if (hit) return hit;
  const icon = L.divIcon({
    className: "",
    html: salaryPinMarkup({
      pill: escHtml(pinLabel(pill, tier)),
      jobId: escHtml(jobId),
      shadow: pinShadow(tier),
    }),
    iconSize: [0, 0],
    iconAnchor: [0, 0],
  });
  cache.set(key, icon);
  return icon;
}

const dotCache = new Map<string, L.DivIcon>();

/**
 * A plain volt dot for the zoomed-out view (Joyme-style: dots from afar, salary
 * pills up close) — smaller and quieter than the pill so a city-wide view
 * doesn't drown in price tags. Premium listings dot a touch larger. Carries the
 * same `data-job-id` so hover/click delegation works identically to the pill.
 */
export function dotPinIcon(jobId: string, tier: PinTier): L.DivIcon {
  const key = `dot|${jobId}|${tier ?? ""}`;
  const hit = dotCache.get(key);
  if (hit) return hit;
  const size = tier === "premium" ? 15 : 12;
  const icon = L.divIcon({
    className: "",
    html:
      `<span data-job-id="${escHtml(jobId)}" style="display:block;` +
      `width:${size}px;height:${size}px;border-radius:9999px;` +
      `transform:translate(-50%,-50%);background:#C7FB00;` +
      `border:2px solid #0A0A0A;box-shadow:0 0 0 1px rgba(199,251,0,.4)"></span>`,
    iconSize: [0, 0],
    iconAnchor: [0, 0],
  });
  dotCache.set(key, icon);
  return icon;
}
