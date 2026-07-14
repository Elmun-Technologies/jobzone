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
