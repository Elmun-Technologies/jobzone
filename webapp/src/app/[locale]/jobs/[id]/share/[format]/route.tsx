import { getJobById } from "@/lib/data/jobs";
import { siteUrl } from "@/lib/seo";
import { type CreativeFormat, jobCreative } from "@/lib/share/creative";

// Serves the downloadable share creatives for a vacancy:
//   /{locale}/jobs/{id}/share/story  → 1080×1920 (Instagram Stories)
//   /{locale}/jobs/{id}/share/post   → 1080×1080 (Instagram post)
//   /{locale}/jobs/{id}/share/og     → 1200×630  (link preview, same as og:image)
// The employer share UI links here; Phase 2 (mobile "Share to Stories") reuses
// the same URLs as the Instagram background asset.
const FORMATS = new Set<CreativeFormat>(["og", "story", "post"]);

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ locale: string; id: string; format: string }> },
) {
  const { locale, id, format } = await params;
  if (!FORMATS.has(format as CreativeFormat)) {
    return new Response("Not found", { status: 404 });
  }
  const job = await getJobById(id);
  if (!job) return new Response("Not found", { status: 404 });
  return await jobCreative(job, format as CreativeFormat, locale, siteUrl());
}
