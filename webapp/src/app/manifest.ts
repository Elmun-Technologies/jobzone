import type { MetadataRoute } from "next";

/**
 * PWA manifest — makes Yolla installable on Android (Add to Home Screen)
 * and lets Chrome/Safari treat the site as an app when the visitor pins it.
 * Route lives at /manifest.webmanifest; the locale layout advertises it via
 * `metadata.manifest`, so every locale root gets the correct <link>.
 *
 * Colors mirror the design tokens (volt on ink); the icon reuses the same
 * SVG the browser already fetches for the favicon so we don't ship a
 * bitmap pair that would drift out of sync with the wordmark.
 */
export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Yollla — O'zbekistondagi ishlar",
    short_name: "Yollla",
    description:
      "Yollla — O'zbekistonda ishonchli ish topish va xodim yollash platformasi.",
    start_url: "/uz",
    scope: "/",
    display: "standalone",
    background_color: "#ffffff",
    theme_color: "#c7fb00",
    lang: "uz",
    icons: [
      {
        src: "/icon.svg",
        sizes: "any",
        type: "image/svg+xml",
        purpose: "any",
      },
    ],
  };
}
