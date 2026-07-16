import { NextResponse } from "next/server";

/**
 * Android Digital Asset Links (App Links verification).
 *
 * Android fetches this at install time when the app declares
 * `<intent-filter android:autoVerify="true">` for https://www.yollla.uz.
 * If the SHA-256 fingerprint here matches the release APK's signing cert,
 * Android opens Yolla directly on tapped links; otherwise the link routes
 * to Chrome.
 *
 * The fingerprint is served from `ANDROID_APP_SHA256_FINGERPRINT` (a colon-
 * separated hex string, e.g. "14:6D:E9:83:...:B3"). When unset the route
 * returns an empty array so the endpoint is still 200 (Android tolerates
 * that during rollout), but verification will fail until the env is
 * populated in Vercel — see docs/android-signing.md §4.
 *
 * Play App Signing note: after enrolling in Play App Signing, Play resigns
 * the app with a Google-managed key. The SHA-256 that ships to devices is
 * Play's "App signing certificate" (Play Console → App integrity → App
 * signing), not the upload key. Both fingerprints are safe to list here —
 * useful during the transition window.
 */
export const dynamic = "force-static";
export const revalidate = 3600;

const PACKAGE_NAME = "io.jobzone.jobzone";

function parseFingerprints(raw: string | undefined): string[] {
  if (!raw) return [];
  return raw
    .split(",")
    .map((f) => f.trim())
    .filter((f) => f.length > 0);
}

export function GET() {
  const fingerprints = parseFingerprints(
    process.env.ANDROID_APP_SHA256_FINGERPRINT,
  );
  const body = [
    {
      relation: [
        "delegate_permission/common.handle_all_urls",
        "delegate_permission/common.get_login_creds",
      ],
      target: {
        namespace: "android_app",
        package_name: PACKAGE_NAME,
        sha256_cert_fingerprints: fingerprints,
      },
    },
  ];
  return NextResponse.json(body, {
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "public, max-age=3600, s-maxage=3600",
    },
  });
}
