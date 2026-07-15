import { ImageResponse } from "next/og";

import { getJobById } from "@/lib/data/jobs";
import { siteUrl } from "@/lib/seo";
import { CREATIVE_SIZES, jobCreative } from "@/lib/share/creative";

// The link-preview image for a vacancy. As a file-convention `opengraph-image`,
// Next wires the result into the page's `og:image` / `twitter:image`
// automatically — so every shared job link renders a branded card.
export const alt = "Yollla — vacancy";
export const size = CREATIVE_SIZES.og;
export const contentType = "image/png";

export default async function Image({
  params,
}: {
  params: Promise<{ locale: string; id: string }>;
}) {
  const { locale, id } = await params;
  const job = await getJobById(id);
  if (job) return jobCreative(job, "og", locale, siteUrl());

  // Branded fallback when the job can't be loaded (deleted, or hit directly).
  return new ImageResponse(
    (
      <div
        style={{
          width: size.width,
          height: size.height,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          backgroundColor: "#0A0A0A",
          color: "#F3F3F1",
          fontSize: 96,
          fontWeight: 800,
          letterSpacing: -4,
          fontFamily: "sans-serif",
        }}
      >
        yollla
      </div>
    ),
    { ...size },
  );
}
