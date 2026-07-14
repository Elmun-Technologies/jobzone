import Script from "next/script";

/**
 * GA4 gtag.js loader — matches the snippet Google Analytics prints under
 * "Web stream details", but rendered through next/script so hydration
 * doesn't fight the tag insertion and the loader script defers to
 * afterInteractive (no LCP hit).
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
        strategy="afterInteractive"
      />
      <Script id="gtag-init" strategy="afterInteractive">
        {`window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}
gtag('js', new Date());
gtag('config', '${measurementId}');`}
      </Script>
    </>
  );
}
