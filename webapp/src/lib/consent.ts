/**
 * Cookie consent — a single, boring, GDPR/UZ-aligned gate for third-party
 * analytics. The rule we enforce: nothing that talks to Google / Yandex /
 * Meta / PostHog loads until the visitor clicks accept. Vercel Analytics
 * and Speed Insights are Vercel first-party (no third-party host, no
 * cross-site cookies), so they stay outside the gate.
 *
 * State model: one cookie `yolla_consent` with three possible reads —
 *   granted  → all analytics on
 *   denied   → all analytics off, banner hidden (visitor said no)
 *   missing  → all analytics off, banner shown (visitor hasn't chosen)
 *
 * Server side (layout, RSC) reads it via cookies(); client side (banner,
 * "manage cookies" link) reads/writes document.cookie directly. Both agree
 * on the same name + values so there's no drift.
 */

export const CONSENT_COOKIE = "yolla_consent";
export type ConsentValue = "granted" | "denied";

// One year, matching most cookie-consent frameworks. The visitor can
// change their mind by clicking "Cookie settings" in the footer.
export const CONSENT_MAX_AGE_SECONDS = 60 * 60 * 24 * 365;

export function parseConsent(raw: string | undefined | null): ConsentValue | null {
  if (raw === "granted" || raw === "denied") return raw;
  return null;
}
