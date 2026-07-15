import { ImageResponse } from "next/og";

import type { Job } from "@/lib/data/types";
import { salaryText } from "@/lib/format";

/**
 * One shared renderer for a vacancy's share creative, in the Yolla brand
 * (ink #0A0A0A on white, volt #C7FB00 accent). It backs three surfaces from a
 * single design:
 *   - `og`    1200×630  — the link preview (og:image / twitter card)
 *   - `story` 1080×1920 — an Instagram Stories-ready image
 *   - `post`  1080×1080 — an Instagram feed post
 *
 * Rendered server-side via `next/og` (Satori), so every device gets the same
 * result and the same image doubles as an automatic rich preview wherever the
 * job link is shared. Satori supports only a flexbox subset with inline styles,
 * so this is deliberately plain (no Tailwind, explicit `display: flex`).
 */
export type CreativeFormat = "og" | "story" | "post";

export const CREATIVE_SIZES: Record<
  CreativeFormat,
  { width: number; height: number }
> = {
  og: { width: 1200, height: 630 },
  story: { width: 1080, height: 1920 },
  post: { width: 1080, height: 1080 },
};

const INK = "#0A0A0A";
const VOLT = "#C7FB00";
const GREY = "#565B4D";
const FAINT = "#9A9F8F";
const WHITE = "#FFFFFF";

type Lang = "uz" | "ru" | "en";

const LABELS: Record<Lang, { pay: string; negotiable: string; cta: string }> = {
  uz: {
    pay: "Maosh",
    negotiable: "Kelishilgan",
    cta: "Ilovada ariza topshiring",
  },
  ru: {
    pay: "Зарплата",
    negotiable: "Договорная",
    cta: "Откликнуться в приложении",
  },
  en: { pay: "Salary", negotiable: "Negotiable", cta: "Apply in the app" },
};

function lang(locale: string): Lang {
  return locale === "ru" || locale === "en" ? locale : "uz";
}

/** Location line: prefer the free-text location, fall back to city/country. */
function creativeLocation(job: Job): string {
  return job.location ?? [job.city, job.country].filter(Boolean).join(", ");
}

/** Short host for the on-image CTA (e.g. "yolla.uz"), never a scheme. */
function shortHost(siteUrl: string): string {
  return siteUrl.replace(/^https?:\/\//, "").replace(/\/$/, "");
}

/**
 * Build the creative for a job in a given format. Returns an `ImageResponse`
 * (a `Response`), so both the `opengraph-image` file convention and the
 * download route handlers can just return it.
 */
export function jobCreative(
  job: Job,
  format: CreativeFormat,
  locale: string,
  siteUrl: string,
): ImageResponse {
  const size = CREATIVE_SIZES[format];
  const L = LABELS[lang(locale)];
  // Everything scales off a 1080-wide baseline so all three formats share one
  // set of proportions.
  const u = size.width / 1080;
  const isOg = format === "og";
  const pay = salaryText(job) ?? L.negotiable;
  const loc = creativeLocation(job);

  const pad = (isOg ? 64 : 88) * (isOg ? 1 : u);
  const circle = (isOg ? 320 : 520) * (isOg ? 1 : u);

  return new ImageResponse(
    (
      <div
        style={{
          width: size.width,
          height: size.height,
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          position: "relative",
          backgroundColor: WHITE,
          color: INK,
          padding: pad,
          fontFamily: "sans-serif",
          overflow: "hidden",
        }}
      >
        {/* Volt accent — a large circle anchored off the bottom-right corner. */}
        <div
          style={{
            position: "absolute",
            right: -circle * 0.28,
            bottom: -circle * 0.28,
            width: circle,
            height: circle,
            borderRadius: circle,
            backgroundColor: VOLT,
            display: "flex",
          }}
        />

        {/* Brand row */}
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            position: "relative",
          }}
        >
          <div
            style={{
              display: "flex",
              fontSize: 44 * u,
              fontWeight: 800,
              letterSpacing: -2 * u,
              color: INK,
            }}
          >
            yollla
          </div>
          <div
            style={{
              display: "flex",
              fontSize: 26 * u,
              fontWeight: 600,
              color: INK,
              maxWidth: size.width * 0.42,
              overflow: "hidden",
            }}
          >
            {job.companyName}
          </div>
        </div>

        {/* Content block */}
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            position: "relative",
            maxWidth: isOg ? size.width * 0.72 : size.width * 0.86,
          }}
        >
          <div
            style={{
              display: "flex",
              fontSize: (isOg ? 60 : 84) * (isOg ? 1 : u),
              fontWeight: 800,
              letterSpacing: -2 * u,
              lineHeight: 1.02,
              color: INK,
            }}
          >
            {job.title}
          </div>
          <div
            style={{
              display: "flex",
              marginTop: 20 * u,
              fontSize: 30 * u,
              fontWeight: 500,
              color: GREY,
            }}
          >
            {loc}
          </div>
          <div
            style={{
              display: "flex",
              flexDirection: "column",
              marginTop: 44 * u,
            }}
          >
            <div
              style={{
                display: "flex",
                fontSize: 26 * u,
                fontWeight: 600,
                color: FAINT,
              }}
            >
              {L.pay}
            </div>
            <div
              style={{
                display: "flex",
                marginTop: 6 * u,
                fontSize: (isOg ? 44 : 54) * (isOg ? 1 : u),
                fontWeight: 800,
                letterSpacing: -1 * u,
                color: INK,
              }}
            >
              {pay}
            </div>
          </div>
        </div>

        {/* CTA — only on the shareable creatives, not the compact OG card */}
        {isOg ? (
          <div style={{ display: "flex" }} />
        ) : (
          <div
            style={{
              display: "flex",
              alignItems: "center",
              position: "relative",
            }}
          >
            <div
              style={{
                display: "flex",
                alignItems: "center",
                backgroundColor: INK,
                color: VOLT,
                borderRadius: 999,
                padding: `${18 * u}px ${28 * u}px`,
                fontSize: 28 * u,
                fontWeight: 700,
              }}
            >
              {`${L.cta} →`}
            </div>
            <div
              style={{
                display: "flex",
                marginLeft: 24 * u,
                fontSize: 26 * u,
                fontWeight: 600,
                color: GREY,
              }}
            >
              {shortHost(siteUrl)}
            </div>
          </div>
        )}
      </div>
    ),
    { width: size.width, height: size.height },
  );
}
