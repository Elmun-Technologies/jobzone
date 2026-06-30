import type { MetadataRoute } from "next";

import { siteUrl } from "@/lib/seo";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: "*",
      allow: "/",
      // Authenticated areas (added in later phases) shouldn't be crawled.
      disallow: ["/api/", "/*/account/", "/*/employer/"],
    },
    sitemap: `${siteUrl()}/sitemap.xml`,
  };
}
