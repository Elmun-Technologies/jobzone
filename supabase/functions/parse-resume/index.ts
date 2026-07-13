// parse-resume — reads an uploaded CV (PDF or image) and returns structured
// profile fields, so a seeker can auto-fill their Yolla profile from a résumé
// instead of typing everything by hand.
//
// Claude reads the document natively (PDF document block / image block) and is
// forced to emit one tool call with the parsed sections. Requires a Supabase
// JWT (config.toml — not in the verify_jwt=false list). When ANTHROPIC_API_KEY
// isn't set the endpoint returns { available: false } so the client falls back
// to manual entry rather than erroring.
//
// Optional function secrets:
//   ANTHROPIC_API_KEY  — enables parsing (else { available: false })

import { corsHeaders, json } from "../_shared/cors.ts";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");
const CLAUDE_MODEL = "claude-opus-4-8";

const LANG: Record<string, string> = {
  uz: "Uzbek (Latin script)",
  ru: "Russian",
  en: "English",
};

const emitProfileTool = {
  name: "emit_profile",
  description: "Return the structured profile parsed from the résumé.",
  input_schema: {
    type: "object",
    properties: {
      fullName: { type: "string", description: "The candidate's full name." },
      headline: {
        type: "string",
        description: "A short current role/title, e.g. 'Driver' or 'Barista'.",
      },
      bio: {
        type: "string",
        description: "A 2-3 sentence professional summary about the person.",
      },
      skills: {
        type: "array",
        items: { type: "string" },
        description: "Individual skills, each a short phrase.",
      },
      experiences: {
        type: "array",
        items: {
          type: "object",
          properties: {
            title: { type: "string" },
            companyName: { type: "string" },
            startYear: { type: "integer" },
            endYear: {
              type: "integer",
              description: "Omit if the role is current/ongoing.",
            },
            isCurrent: { type: "boolean" },
            description: { type: "string" },
          },
          required: ["title"],
        },
      },
      educations: {
        type: "array",
        items: {
          type: "object",
          properties: {
            school: { type: "string" },
            degree: { type: "string" },
            field: { type: "string" },
            startYear: { type: "integer" },
            endYear: { type: "integer" },
          },
          required: ["school"],
        },
      },
    },
    required: ["skills", "experiences", "educations"],
  },
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "method not allowed" }, 405);
  }

  if (!ANTHROPIC_API_KEY) return json({ available: false });

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch (_) {
    return json({ error: "invalid json" }, 400);
  }

  const fileBase64 = String(body.fileBase64 ?? "");
  const mimeType = String(body.mimeType ?? "");
  const lang = LANG[String(body.locale ?? "uz")] ?? LANG.uz;
  if (!fileBase64) return json({ error: "fileBase64 required" }, 400);

  // Claude reads PDFs as a `document` block and images as an `image` block.
  const isPdf = mimeType === "application/pdf";
  const isImage = mimeType.startsWith("image/");
  if (!isPdf && !isImage) {
    // DOC/DOCX etc. can't be read natively — tell the client to fall back.
    return json({ available: false, reason: "unsupported_type" });
  }

  const source = {
    type: "base64",
    media_type: isPdf ? "application/pdf" : mimeType,
    data: fileBase64,
  };
  const fileBlock = isPdf
    ? { type: "document", source }
    : { type: "image", source };

  const system =
    "You extract structured profile data from a job-seeker's résumé for " +
    "Yolla, a blue-collar job marketplace in Uzbekistan. Return ONLY what the " +
    `résumé actually states — never invent facts. Write the headline and bio ` +
    `in ${lang}. Keep skills as short individual phrases. Use 4-digit years.`;

  try {
    const resp = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: CLAUDE_MODEL,
        max_tokens: 2048,
        system,
        tools: [emitProfileTool],
        tool_choice: { type: "tool", name: "emit_profile" },
        messages: [
          {
            role: "user",
            content: [
              fileBlock,
              { type: "text", text: "Parse this résumé into the profile." },
            ],
          },
        ],
      }),
    });

    if (!resp.ok) {
      console.error("anthropic parse-resume", resp.status, await resp.text());
      return json({ available: false, reason: "provider_error" });
    }
    const data = await resp.json();
    const block = Array.isArray(data?.content)
      ? data.content.find(
        (b: Record<string, unknown>) => b?.type === "tool_use",
      )
      : null;
    const profile = (block?.input ?? {}) as Record<string, unknown>;
    return json({ available: true, profile });
  } catch (e) {
    console.error("parse-resume failed", e);
    return json({ available: false, reason: "provider_error" });
  }
});
