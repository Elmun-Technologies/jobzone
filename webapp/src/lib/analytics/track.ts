/**
 * Central client-side event dispatcher — fans a single call out to
 * every enabled analytics endpoint (GA4, PostHog, Meta Pixel, Yandex
 * Metrica) so a component that wants to record "apply_click" does not
 * have to know which vendors are on today.
 *
 * The helper is a no-op on the server (window / fbq / gtag are
 * client-only) and each per-vendor call is guarded — a missing SDK
 * (env not set) is a silent skip, so shipping this module dark is
 * safe.
 *
 * Event names use snake_case (GA4 convention). PostHog accepts them
 * verbatim; Meta Pixel maps standard events (Lead / CompleteRegistration
 * / Search / SubmitApplication) with a fallback to `trackCustom` for
 * anything else.
 */

type EventName =
  | "job_view"
  | "job_apply_click"
  | "job_apply_submit"
  | "search_performed"
  | "saved_search_created"
  | "signup_complete"
  | "vacancy_post_start"
  | "vacancy_post_complete"
  | "wallet_topup_pending"
  // Two lightweight engagement events — currently GA/PostHog only, no Meta
  // standard-event mapping. Adding them to the union so calls are compile-safe
  // and so a typo (`bookmarked` etc.) fails at the call site.
  | "phone_click"
  | "bookmark_added";

type EventProps = Record<string, string | number | boolean | null | undefined>;

// Meta Pixel standard events — anything else routes through `trackCustom`.
// Names are the exact strings Meta expects (case-sensitive).
const META_STANDARD: Partial<Record<EventName, string>> = {
  job_apply_click: "Lead",
  job_apply_submit: "SubmitApplication",
  search_performed: "Search",
  signup_complete: "CompleteRegistration",
  vacancy_post_complete: "SubmitApplication",
  wallet_topup_pending: "InitiateCheckout",
};

// window.gtag / window.fbq / window.ym / window.posthog aren't in the
// default lib.dom types — narrow to `unknown` and call defensively.
type W = Window & {
  gtag?: (...args: unknown[]) => void;
  fbq?: (...args: unknown[]) => void;
  ym?: (id: number, action: string, ...args: unknown[]) => void;
  posthog?: { capture?: (name: string, props?: EventProps) => void };
};

export function track(name: EventName, props: EventProps = {}): void {
  if (typeof window === "undefined") return;
  const w = window as W;

  // GA4 — accepts arbitrary custom event names.
  try {
    w.gtag?.("event", name, props);
  } catch {
    // Never let analytics crash the UI.
  }

  // PostHog — same shape as GA4.
  try {
    w.posthog?.capture?.(name, props);
  } catch {
    /* noop */
  }

  // Yandex.Metrica reachGoal — the counter id must match the loader.
  // Metrica does not accept arbitrary props on goals; we pass them
  // as params for filtering in the report. Env-only (no hardcoded fallback);
  // when `NEXT_PUBLIC_YANDEX_METRICA_ID` is unset the loader also skipped,
  // so `w.ym` is undefined and this branch never fires — but the env read
  // stays first so a misconfigured `w.ym` (stray SDK on the page) can't
  // accidentally receive events aimed at production.
  try {
    const idNum = Number(process.env.NEXT_PUBLIC_YANDEX_METRICA_ID ?? "");
    if (idNum && w.ym) {
      w.ym(idNum, "reachGoal", name, props as Record<string, unknown>);
    }
  } catch {
    /* noop */
  }

  // Meta Pixel — standard events map to `track`, custom to `trackCustom`.
  try {
    const std = META_STANDARD[name];
    if (std) {
      w.fbq?.("track", std, props);
    } else {
      w.fbq?.("trackCustom", name, props);
    }
  } catch {
    /* noop */
  }
}
