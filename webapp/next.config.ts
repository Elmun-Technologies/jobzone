import type { NextConfig } from "next";
import createNextIntlPlugin from "next-intl/plugin";
import { withSentryConfig } from "@sentry/nextjs";

const withNextIntl = createNextIntlPlugin("./src/i18n/request.ts");

const nextConfig: NextConfig = {
  images: {
    // Supabase Storage (public buckets: avatars, company-media, intro-videos)
    // and the picsum placeholders used by mock data.
    remotePatterns: [
      { protocol: "https", hostname: "*.supabase.co" },
      { protocol: "https", hostname: "picsum.photos" },
    ],
  },
};

// Sentry build-time wrap — uploads source maps to Sentry so stack traces
// in the dashboard resolve to the original TypeScript, not the minified
// build. The wrap is a no-op when SENTRY_AUTH_TOKEN is unset (local dev,
// preview builds without the secret) so the Next build still succeeds
// without ever failing on missing credentials.
//
// `tunnelRoute` proxies Sentry ingest through the same origin so ad
// blockers that block `*.sentry.io` don't silently drop error reports —
// a Yolla-scale audience in UZ runs adblock heavily. Route lives at
// /monitoring; Next generates the proxy handler automatically.
//
// `widenClientFileUpload` lifts an old restriction so source maps for
// files inside app/ are actually uploaded. Source maps upload to Sentry
// and are then deleted from the build output by default
// (`sourcemaps.deleteSourcemapsAfterUpload: true`) so the deployed
// bundle doesn't ship them.
export default withSentryConfig(withNextIntl(nextConfig), {
  org: process.env.SENTRY_ORG,
  project: process.env.SENTRY_PROJECT,
  // Silence the "no auth token" warning on local builds — that's the
  // expected state anywhere the secret isn't set.
  silent: !process.env.SENTRY_AUTH_TOKEN,
  authToken: process.env.SENTRY_AUTH_TOKEN,
  widenClientFileUpload: true,
  tunnelRoute: "/monitoring",
});
