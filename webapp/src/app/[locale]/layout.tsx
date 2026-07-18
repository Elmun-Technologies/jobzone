import type { Metadata, Viewport } from "next";
import { Archivo, Space_Mono } from "next/font/google";
import { cookies } from "next/headers";
import { notFound } from "next/navigation";
import { hasLocale, NextIntlClientProvider } from "next-intl";
import { getTranslations, setRequestLocale } from "next-intl/server";
import { Analytics as VercelAnalytics } from "@vercel/analytics/next";
import { SpeedInsights } from "@vercel/speed-insights/next";

import { GoogleAnalytics } from "@/components/analytics/google-analytics";
import { MetaPixel } from "@/components/analytics/meta-pixel";
import { PostHogProvider } from "@/components/analytics/posthog-provider";
import { YandexMetrica } from "@/components/analytics/yandex-metrica";
import { ConsentBanner } from "@/components/consent/consent-banner";
import { SiteBanner } from "@/components/layout/site-banner";
import { SiteFooter } from "@/components/layout/site-footer";
import { SiteHeader } from "@/components/layout/site-header";
import { routing } from "@/i18n/routing";
import { CONSENT_COOKIE, parseConsent } from "@/lib/consent";
import { localeAlternates, siteUrl } from "@/lib/seo";

import "../globals.css";

// Yolla type: Archivo for everything (UI, body, headings via weight, and the
// wordmark at 900) — multilingual (uz Latin + ru Cyrillic). Space Mono for
// numbers/prices/tags. Anton (the board's poster face) is Latin-only, so it is
// intentionally not used on localized text.
const archivo = Archivo({
  variable: "--font-archivo",
  // uz Latin + latin-ext (ʻ/accents). Archivo has no Cyrillic subset, so ru
  // text renders in the Cyrillic-capable system fallback below.
  subsets: ["latin", "latin-ext"],
  fallback: ["system-ui", "sans-serif"],
});
const spaceMono = Space_Mono({
  variable: "--font-space-mono",
  weight: ["400", "700"],
  subsets: ["latin"],
});

// Pre-render every locale at build time.
export function generateStaticParams() {
  return routing.locales.map((locale) => ({ locale }));
}

// theme-color is a Viewport field in Next 13.2+ (the old metadata.themeColor
// is deprecated). Bind it to the same volt-on-ink pair the design tokens use
// so mobile browsers tint the address bar to match the app.
export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#ffffff" },
    { media: "(prefers-color-scheme: dark)", color: "#0a0a0a" },
  ],
};

const OG_LOCALE: Record<string, string> = {
  uz: "uz_UZ",
  ru: "ru_RU",
  en: "en_US",
};

// Public verification / analytics IDs. All env-only, NO hardcoded fallbacks:
// a hardcoded default runs on every preview branch too, contaminating the
// production stream with dev traffic and violating the "dev/preview stays
// silent" invariant. Set each on the production environment in Vercel and
// leave preview/local unset — see .env.example for the full list.
const GOOGLE_SITE_VERIFICATION =
  process.env.NEXT_PUBLIC_GOOGLE_SITE_VERIFICATION ?? "";
const YANDEX_VERIFICATION = process.env.NEXT_PUBLIC_YANDEX_VERIFICATION ?? "";
const GA_MEASUREMENT_ID = process.env.NEXT_PUBLIC_GA_MEASUREMENT_ID ?? "";
const YANDEX_METRICA_ID = process.env.NEXT_PUBLIC_YANDEX_METRICA_ID ?? "";
const META_PIXEL_ID = process.env.NEXT_PUBLIC_META_PIXEL_ID ?? "";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "meta" });
  // metadataBase resolves every relative canonical/og:url/twitter:image below
  // it — without it Next warns and drops relative URLs at build time.
  const primary = OG_LOCALE[locale] ?? OG_LOCALE.uz;
  return {
    metadataBase: new URL(siteUrl()),
    title: { default: t("title"), template: "%s · Yolla" },
    description: t("description"),
    applicationName: "Yolla",
    // Alternates on the layout only cover the localized root (/uz, /ru, /en).
    // Every child page redeclares its own alternates via localeAlternates(...)
    // so canonicals + hreflang are self-referencing on every URL Google finds.
    alternates: localeAlternates(locale, ""),
    openGraph: {
      type: "website",
      siteName: "Yolla",
      title: t("title"),
      description: t("description"),
      // Locale + alternates match how Google/Facebook expect them. Pages that
      // set their own openGraph.title/description override these; siteName
      // and locale keep inheriting.
      locale: primary,
      alternateLocale: Object.values(OG_LOCALE).filter((l) => l !== primary),
    },
    twitter: {
      card: "summary_large_image",
      title: t("title"),
      description: t("description"),
    },
    manifest: "/manifest.webmanifest",
    icons: { icon: "/icon.svg" },
    verification: {
      google: GOOGLE_SITE_VERIFICATION,
      ...(YANDEX_VERIFICATION ? { yandex: YANDEX_VERIFICATION } : {}),
    },
  };
}

// Applies the saved theme before first paint to avoid a flash (see
// node_modules/next/dist/docs/.../preventing-flash-before-hydration.md).
const THEME_SCRIPT = `(function(){try{var t=localStorage.getItem('theme');var m=window.matchMedia('(prefers-color-scheme: dark)').matches;if(t==='dark'||(!t&&m)){document.documentElement.classList.add('dark');}}catch(e){}})();`;

export default async function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  if (!hasLocale(routing.locales, locale)) notFound();
  setRequestLocale(locale);

  // Consent gate: read the cookie once, use it to (a) hide the banner
  // when the visitor already chose and (b) gate every third-party
  // analytics loader so scripts don't reach the browser at all until the
  // visitor has clicked accept. GDPR + UZ personal-data law both require
  // this pattern for non-first-party trackers.
  const consent = parseConsent((await cookies()).get(CONSENT_COOKIE)?.value);
  const analyticsAllowed = consent === "granted";

  return (
    <html
      lang={locale}
      className={`${archivo.variable} ${spaceMono.variable} h-full antialiased`}
      suppressHydrationWarning
    >
      <head>
        <script dangerouslySetInnerHTML={{ __html: THEME_SCRIPT }} />
      </head>
      <body className="bg-background text-foreground flex min-h-full flex-col font-sans">
        <NextIntlClientProvider>
          <SiteBanner />
          <SiteHeader />
          <main className="flex-1">{children}</main>
          <SiteFooter />
          <ConsentBanner initialConsent={consent} />
        </NextIntlClientProvider>
        {analyticsAllowed ? (
          <>
            <GoogleAnalytics measurementId={GA_MEASUREMENT_ID} />
            <YandexMetrica counterId={YANDEX_METRICA_ID} />
            <MetaPixel pixelId={META_PIXEL_ID} />
            <PostHogProvider />
          </>
        ) : null}
        {/* Vercel first-party analytics: Web Analytics (traffic) + Speed
            Insights (real-user Core Web Vitals — LCP/INP/CLS). No cookie
            banner needed, no third-party host. Both no-op in dev. */}
        <VercelAnalytics />
        <SpeedInsights />
      </body>
    </html>
  );
}
