/**
 * The two sounds Yolla makes, synthesized in the browser.
 *
 * Deliberately narrow. A job site that chirps while you scroll is a job site
 * people mute, so nothing here fires on hover, scroll, navigation or an
 * incoming notification. Sound is reserved for the two moments that are worth
 * a sound — the seeker sending an application, and the employer publishing a
 * vacancy — where a confirmation is what the person is waiting for, and where
 * a phone is often being held at arm's length rather than looked at.
 *
 * No audio files: two oscillators through a gain envelope, a couple of hundred
 * bytes of code instead of a network request for an asset that has to load
 * before the moment it belongs to. The AudioContext is created on the first
 * play, which is always inside the click that triggered it, so the browser's
 * autoplay policy is satisfied by construction.
 */

/** localStorage key for the device-level preference. */
export const SOUND_KEY = "yolla:sound";

/**
 * On unless the visitor turned it off. Both sounds are a direct answer to a
 * button the person just pressed, so the default is a confirmation, not an
 * interruption — and the toggle sits next to the theme switch either way.
 */
export function soundEnabled(): boolean {
  try {
    return window.localStorage.getItem(SOUND_KEY) !== "off";
  } catch {
    return true;
  }
}

export function setSoundEnabled(on: boolean): void {
  try {
    window.localStorage.setItem(SOUND_KEY, on ? "on" : "off");
  } catch {
    // Private mode — the preference just won't persist.
  }
  window.dispatchEvent(new CustomEvent(SOUND_CHANGED_EVENT));
}

/** Fired on `window` when the preference changes, so toggles stay in sync. */
export const SOUND_CHANGED_EVENT = "yolla:sound-changed";

let ctx: AudioContext | null = null;

function audioContext(): AudioContext | null {
  if (ctx) return ctx;
  try {
    const Ctor =
      window.AudioContext ??
      (window as unknown as { webkitAudioContext?: typeof AudioContext })
        .webkitAudioContext;
    if (!Ctor) return null;
    ctx = new Ctor();
    return ctx;
  } catch {
    return null;
  }
}

/** One note: a sine with a short attack and an exponential tail. */
function note(
  context: AudioContext,
  frequency: number,
  startAt: number,
  duration: number,
  peak: number,
): void {
  const osc = context.createOscillator();
  const gain = context.createGain();
  // Sine, not square or saw: no harmonics means no edge, which is what keeps
  // this readable as a confirmation rather than a game sound.
  osc.type = "sine";
  osc.frequency.setValueAtTime(frequency, startAt);
  gain.gain.setValueAtTime(0.0001, startAt);
  gain.gain.exponentialRampToValueAtTime(peak, startAt + 0.012);
  gain.gain.exponentialRampToValueAtTime(0.0001, startAt + duration);
  osc.connect(gain).connect(context.destination);
  osc.start(startAt);
  osc.stop(startAt + duration + 0.02);
}

/**
 * A two-note rise (E6 → A6, a rising fourth) for a completed action.
 *
 * Quiet, ~300ms, and it resolves upward — the shape every "done" sound has,
 * because a falling interval reads as a failure however nicely it's voiced.
 */
export function playSuccess(): void {
  if (typeof window === "undefined" || !soundEnabled()) return;
  const context = audioContext();
  if (!context) return;
  try {
    // A context created before a gesture (or backgrounded by iOS) starts
    // suspended; resuming inside the click is what makes it audible.
    if (context.state === "suspended") void context.resume();
    const now = context.currentTime;
    note(context, 1318.5, now, 0.14, 0.09);
    note(context, 1760, now + 0.09, 0.22, 0.075);
  } catch {
    // Audio is decoration. Never let it break the action it accompanies.
  }
}
