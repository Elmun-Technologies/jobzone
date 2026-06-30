"use client";

import { Moon, Sun } from "lucide-react";
import { useTranslations } from "next-intl";
import { useSyncExternalStore } from "react";

import { Button } from "@/components/ui/button";

// Subscribe to <html> class changes so the icon reflects the active theme.
function subscribe(onChange: () => void) {
  const observer = new MutationObserver(onChange);
  observer.observe(document.documentElement, {
    attributes: true,
    attributeFilter: ["class"],
  });
  return () => observer.disconnect();
}

const isDark = () => document.documentElement.classList.contains("dark");

/**
 * Light/dark toggle. Reads the current theme from the DOM via
 * `useSyncExternalStore` (avoids hydration mismatch and setState-in-effect),
 * and persists to `localStorage` — the inline script in the root layout applies
 * the saved value before first paint.
 */
export function ThemeToggle() {
  const t = useTranslations("theme");
  const dark = useSyncExternalStore(
    subscribe,
    isDark,
    () => false, // server snapshot: assume light
  );

  function toggle() {
    const next = !dark;
    document.documentElement.classList.toggle("dark", next);
    try {
      localStorage.setItem("theme", next ? "dark" : "light");
    } catch {
      // Ignore storage failures (private mode, etc.).
    }
  }

  return (
    <Button
      variant="ghost"
      size="icon"
      onClick={toggle}
      aria-label={dark ? t("light") : t("dark")}
      suppressHydrationWarning
    >
      {dark ? <Sun /> : <Moon />}
    </Button>
  );
}
