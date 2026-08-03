import type { Metadata, Viewport } from "next";
import { Archivo, Space_Mono } from "next/font/google";
import { notFound } from "next/navigation";
import { Suspense } from "react";
import { hasLocale, NextIntlClientProvider } from "next-intl";
import { getTranslations, setRequestLocale } from "next-intl/server";
import { Analytics as VercelAnalytics } from "@vercel/analytics/next";
import { SpeedInsights } from "@vercel/speed-insights/next";

import { SavedJobsProvider } from "@/components/jobs/saved-jobs-provider";
import { FirstVisitShell } from "@/components/layout/first-visit-shell";
import { SiteBanner } from "@/components/layout/site-banner";
import { SiteFooter } from "@/components/layout/site-footer";
import { SiteHeader } from "@/components/layout/site-header";
import { SiteTabBar } from "@/components/layout/site-tab-bar";
import { Toaster } from "@/components/ui/toast";
import { routing } from "@/i18n/routing";
import { THEME_COOKIE, themeCookieString } from "@/lib/theme";
import { localeAlternates, siteUrl } from "@/lib/seo";

import "../globals.css";

// Yollla type: Archivo for everything (UI, body, headings via weight, and the
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
    { media: "(prefers-color-scheme: dark)", color: "#181817" },
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
    title: { default: t("title"), template: "%s · Yollla" },
    description: t("description"),
    applicationName: "Yollla",
    // Alternates on the layout only cover the localized root (/uz, /ru, /en).
    // Every child page redeclares its own alternates via localeAlternates(...)
    // so canonicals + hreflang are self-referencing on every URL Google finds.
    alternates: localeAlternates(locale, ""),
    openGraph: {
      type: "website",
      siteName: "Yollla",
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

// The theme, applied before first paint on every document load. The server
// deliberately does not render it: reading the cookie here would make this
// layout dynamic and, with it, every route in the app (see lib/theme.ts).
// The language switch is a document load precisely so this script gets to run
// again and the choice survives it (lib/locale-nav.ts).
//
// It reads the cookie FIRST and localStorage second, and it never bails early:
// an earlier version returned as soon as it saw a cookie, on the assumption
// that the server had already rendered the class — with the server out of that
// business, that early return meant every returning dark-mode visitor got a
// white page until they toggled again.
const THEME_SCRIPT = `(function(){try{var d=document.documentElement;var m=/(?:^|; )${THEME_COOKIE}=(dark|light)/.exec(document.cookie);var t=m?m[1]:localStorage.getItem('theme');if(t!=='dark'&&t!=='light'){t=window.matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light';}d.classList.toggle('dark',t==='dark');try{localStorage.setItem('theme',t);}catch(e){}document.cookie=t==='dark'?'${themeCookieString("dark")}':'${themeCookieString("light")}';}catch(e){}})();`;

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

  return (
    <html
      lang={locale}
      className={`${archivo.variable} ${spaceMono.variable} h-full antialiased`}
      suppressHydrationWarning
    >
      <head>
        <script dangerouslySetInnerHTML={{ __html: THEME_SCRIPT }} />
      </head>
      {/* `pb-[var(--tabbar)]` clears the fixed phone tab bar; the token is 0 from
          `md` up, where the bar is hidden (see globals.css). */}
      <body className="bg-background text-foreground flex min-h-full flex-col pb-[var(--tabbar)] font-sans">
        <NextIntlClientProvider>
          {/* Saved-job state is fetched in the browser (see the provider) so
              that public pages don't have to read the session — that single
              per-visitor read is what used to keep them off the CDN. */}
          <SavedJobsProvider>
            <SiteBanner />
            <SiteHeader />
            <main className="flex-1">{children}</main>
            <SiteFooter />
            <SiteTabBar />
            {/* Cookie bar, first-visit language sheet and the trackers they
              gate — the only parts of the shell that read the request. Behind
              a boundary they are a hole in a static page instead of the reason
              the whole app renders per request. */}
            <Suspense fallback={null}>
              <FirstVisitShell locale={locale} />
            </Suspense>
            {/* Mounted once for the whole app: toast() pushes to a module-level
              store, so any client component can raise one without a provider
              in its own tree. */}
            <Toaster />
          </SavedJobsProvider>
        </NextIntlClientProvider>
        {/* Vercel first-party analytics: Web Analytics (traffic) + Speed
            Insights (real-user Core Web Vitals — LCP/INP/CLS). No cookie
            banner needed, no third-party host. Both no-op in dev. */}
        <VercelAnalytics />
        <SpeedInsights />
      </body>
    </html>
  );
}
