import { describe, expect, it } from "vitest";

import {
  THEME_COOKIE,
  THEME_MAX_AGE_SECONDS,
  parseTheme,
  themeCookieString,
} from "@/lib/theme";

// The root layout renders the `dark` class from this cookie, and the toggle
// and the first-visit inline script both write it. If the three ever disagree
// the theme silently resets — which is the bug this replaced.
describe("parseTheme", () => {
  it("accepts the two values the app writes", () => {
    expect(parseTheme("dark")).toBe("dark");
    expect(parseTheme("light")).toBe("light");
  });

  it("treats anything else as no choice made", () => {
    // No cookie yet (first visit), or a value from a hand-edited jar.
    expect(parseTheme(undefined)).toBeNull();
    expect(parseTheme(null)).toBeNull();
    expect(parseTheme("")).toBeNull();
    expect(parseTheme("Dark")).toBeNull();
    expect(parseTheme("system")).toBeNull();
  });
});

describe("themeCookieString", () => {
  it("scopes to the whole site so every locale prefix sees it", () => {
    expect(themeCookieString("dark")).toContain("path=/");
  });

  it("persists for a year and is not sent cross-site", () => {
    const s = themeCookieString("light");
    expect(s).toContain(`max-age=${THEME_MAX_AGE_SECONDS}`);
    expect(s).toContain("SameSite=Lax");
  });

  it("round-trips through parseTheme", () => {
    for (const value of ["dark", "light"] as const) {
      const written = themeCookieString(value);
      const read = written.match(
        new RegExp(`${THEME_COOKIE}=(dark|light)`),
      )?.[1];
      expect(parseTheme(read)).toBe(value);
    }
  });
});
