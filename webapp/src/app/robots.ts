import type { MetadataRoute } from "next";

import { siteUrl } from "@/lib/seo";

// Private/auth paths — same across every rule set. Kept as a constant so
// tightening the disallow list is a one-line change.
const DISALLOW_PRIVATE = [
  "/api/",
  "/*/account/",
  "/*/employer/",
  "/*/admin/",
];

// Explicit AI / generative-search crawlers. Listing each User-agent
// separately is redundant with the `*` rule (which already allows them),
// but the extra line is the recognised signal in the space: an operator
// that wants AI systems to index their content, versus one that hasn't
// decided. It also documents intent for anyone reading robots.txt later.
//
// Sources:
//   OpenAI      → GPTBot / OAI-SearchBot / ChatGPT-User
//   Anthropic   → ClaudeBot / Claude-User / anthropic-ai
//   Perplexity  → PerplexityBot / Perplexity-User
//   Google      → Google-Extended (opt-in for Gemini/Vertex training)
//   Apple       → Applebot-Extended (opt-in for Apple Intelligence)
//   Amazon      → Amazonbot (Alexa / Rufus)
//   ByteDance   → Bytespider (Doubao / TikTok search)
//   Common Crawl→ CCBot
//   DuckDuckGo  → DuckAssistBot
//   Cohere      → cohere-ai
//   Yandex      → YandexAdditional (opt-in for AI training on Yandex data)
const AI_BOTS = [
  "GPTBot",
  "OAI-SearchBot",
  "ChatGPT-User",
  "ClaudeBot",
  "Claude-User",
  "anthropic-ai",
  "PerplexityBot",
  "Perplexity-User",
  "Google-Extended",
  "Applebot-Extended",
  "Amazonbot",
  "Bytespider",
  "CCBot",
  "DuckAssistBot",
  "cohere-ai",
  "YandexAdditional",
];

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      // Catch-all — everything indexable except authenticated areas.
      {
        userAgent: "*",
        allow: "/",
        disallow: DISALLOW_PRIVATE,
      },
      // Every named AI/GEO crawler gets the same allow-list explicitly so
      // an operator reading robots.txt sees the intent, and any bot that
      // uses UA-specific rule matching (rather than falling back to `*`)
      // still picks it up.
      {
        userAgent: AI_BOTS,
        allow: "/",
        disallow: DISALLOW_PRIVATE,
      },
    ],
    sitemap: `${siteUrl()}/sitemap.xml`,
  };
}
