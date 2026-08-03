import { GoogleAnalytics } from "@/components/analytics/google-analytics";
import { MetaPixel } from "@/components/analytics/meta-pixel";
import { PostHogProvider } from "@/components/analytics/posthog-provider";
import { YandexMetrica } from "@/components/analytics/yandex-metrica";

// Public verification / analytics IDs. All env-only, NO hardcoded fallbacks:
// a hardcoded default runs on every preview branch too, contaminating the
// production stream with dev traffic and violating the "dev/preview stays
// silent" invariant. Set each on the production environment in Vercel and
// leave preview/local unset — see .env.example for the full list.
const GA_MEASUREMENT_ID = process.env.NEXT_PUBLIC_GA_MEASUREMENT_ID ?? "";
const YANDEX_METRICA_ID = process.env.NEXT_PUBLIC_YANDEX_METRICA_ID ?? "";
const META_PIXEL_ID = process.env.NEXT_PUBLIC_META_PIXEL_ID ?? "";

/**
 * The third-party trackers, mounted only once consent has been granted — the
 * caller (FirstVisitShell) owns that decision, because it is the component
 * allowed to read the cookie.
 *
 * Split out of the root layout so the layout itself never reads a cookie: the
 * scripts load behind a Suspense boundary while the page ships from the CDN.
 */
export function AnalyticsScripts() {
  return (
    <>
      <GoogleAnalytics measurementId={GA_MEASUREMENT_ID} />
      <YandexMetrica counterId={YANDEX_METRICA_ID} />
      <MetaPixel pixelId={META_PIXEL_ID} />
      <PostHogProvider />
    </>
  );
}
