"use client";

import { Volume2, VolumeX } from "lucide-react";
import { useTranslations } from "next-intl";
import { useSyncExternalStore } from "react";

import { Button } from "@/components/ui/button";
import {
  playSuccess,
  setSoundEnabled,
  SOUND_CHANGED_EVENT,
  soundEnabled,
} from "@/lib/sound";

function subscribe(onChange: () => void) {
  window.addEventListener(SOUND_CHANGED_EVENT, onChange);
  // Another tab may have flipped it.
  window.addEventListener("storage", onChange);
  return () => {
    window.removeEventListener(SOUND_CHANGED_EVENT, onChange);
    window.removeEventListener("storage", onChange);
  };
}

/**
 * Mute switch for the two confirmation sounds (see lib/sound.ts).
 *
 * Sits with the theme and language switches rather than in account settings,
 * because it is a property of the device you are holding, not of the account —
 * the same person wants sound at home and silence in an open-plan office, and
 * a guest filling in the apply form has no account to store it against.
 *
 * Turning it back ON plays the sound immediately: a mute switch you can't hear
 * the effect of is a mute switch nobody trusts.
 */
export function SoundToggle() {
  const t = useTranslations("sound");
  const on = useSyncExternalStore(
    subscribe,
    soundEnabled,
    () => true, // server snapshot: the default
  );

  return (
    <Button
      variant="ghost"
      size="icon"
      onClick={() => {
        const next = !on;
        setSoundEnabled(next);
        if (next) playSuccess();
      }}
      aria-label={on ? t("mute") : t("unmute")}
      aria-pressed={on}
      suppressHydrationWarning
    >
      {on ? <Volume2 /> : <VolumeX />}
    </Button>
  );
}
