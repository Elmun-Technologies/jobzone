import Script from "next/script";

/**
 * GA4 gtag.js loader — matches the snippet Google Analytics prints under
 * "Web stream details", but rendered through next/script with
 * strategy="lazyOnload" so the loader runs during the browser's idle
 * window well after LCP. GA4's initial page_view event still fires on
 * that same idle tick, so per-page counts stay correct.
 *
 * Renders nothing when `measurementId` is empty — a preview branch or a
 * local dev run without the env set stays silent instead of polluting the
 * production stream with dev traffic.
 */
export function GoogleAnalytics({
  measurementId,
}: {
  measurementId: string;
}) {
  if (!measurementId) return null;
  return (
    <>
      <Script
        async
        src={`https://www.googletagmanager.com/gtag/js?id=${measurementId}`}
        strategy="lazyOnload"
      />
      <Script id="gtag-init" strategy="lazyOnload">
        {`window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}
gtag('js', new Date());
gtag('config', '${measurementId}');`}
      </Script>
    </>
  );
}
