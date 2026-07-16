import { NextResponse } from "next/server";

/**
 * Apple App Site Association (Universal Links verification).
 *
 * iOS fetches this when the app declares
 * `com.apple.developer.associated-domains = ["applinks:www.yollla.uz",
 *  "applinks:yollla.uz"]` in Runner.entitlements. If Apple can match the
 * appID against the app's team + bundle id, HTTPS taps to yollla.uz open
 * Yolla directly instead of Safari.
 *
 * appID format is `TEAMID.io.jobzone.jobzone`. Team ID lives in
 * `IOS_APP_TEAM_ID` (Vercel env). When unset, the response is still 200
 * with an empty `details` — Apple won't verify until the env is set, but
 * the endpoint won't 404 either (Apple caches negative responses
 * aggressively).
 *
 * IMPORTANT: this file must be served with `application/json` and NO file
 * extension — Apple validators reject text/plain and reject the .json
 * extension. Next.js route handlers give us both.
 */
export const dynamic = "force-static";
export const revalidate = 3600;

const BUNDLE_ID = "io.jobzone.jobzone";

export function GET() {
  const teamId = process.env.IOS_APP_TEAM_ID?.trim();
  const appIDs = teamId ? [`${teamId}.${BUNDLE_ID}`] : [];
  const body = {
    applinks: {
      // Modern (iOS 13+) shape: one `details` entry per bundle-family with
      // path components declaring which URLs the app claims. Wildcards match
      // subroutes (e.g. /jobs/[id]/apply). NOT filters unwanted routes.
      details: appIDs.map((appID) => ({
        appIDs: [appID],
        components: [
          { "/": "/jobs/*" },
          { "/": "/companies/*" },
          { "/": "/ish/*" },
          { "/": "/resumes/*" },
        ],
      })),
    },
    // webcredentials lets iOS AutoFill offer Yolla credentials on the
    // domain. Same appID array covers it.
    webcredentials: { apps: appIDs },
  };
  return NextResponse.json(body, {
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "public, max-age=3600, s-maxage=3600",
    },
  });
}
