"use client";

import { useEffect, useRef } from "react";

import { playSuccess } from "@/lib/sound";

/**
 * Plays the confirmation sound once, when a success screen appears.
 *
 * Renders nothing. It exists because the two moments worth a sound —
 * "application sent", "vacancy published" — are both server-rendered
 * confirmations reached by a redirect, so there is no click handler left to
 * hang the sound on by the time the good news is on screen.
 *
 * `useRef` rather than plain effect state: React runs effects twice in
 * development's strict mode, and a doubled chime is exactly the kind of
 * cheapness this is trying to avoid.
 */
export function Celebrate() {
  const played = useRef(false);

  useEffect(() => {
    if (played.current) return;
    played.current = true;
    playSuccess();
  }, []);

  return null;
}
