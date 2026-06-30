import { defineRouting } from "next-intl/routing";

/**
 * Locale routing for the Jobzone web app.
 *
 * - `uz` is the default (primary market), `ru` and `en` are secondary.
 * - `localePrefix: "always"` prefixes every locale (`/uz`, `/ru`, `/en`) so
 *   each page has one canonical, hreflang-friendly URL — best for SEO.
 */
export const routing = defineRouting({
  locales: ["uz", "ru", "en"],
  defaultLocale: "uz",
  localePrefix: "always",
});

export type Locale = (typeof routing.locales)[number];
