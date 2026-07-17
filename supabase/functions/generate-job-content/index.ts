// generate-job-content — AI assist for employers (job-post drafting + applicant
// ranking).
//
// `draft` writes the job-post sections (description / responsibilities /
// requirements / benefits). When ANTHROPIC_API_KEY is set it calls the Claude
// Messages API for real, localized, on-topic copy; otherwise it falls back to
// the built-in templates so the "AI Генерация" button always works (offline, in
// dev, or before a key is provisioned). `rank` is rule-based (skill overlap).
// The request/response contract is identical in every mode, so callers never
// change.
//
// Optional function secrets:
//   ANTHROPIC_API_KEY  — enables real Claude drafting (else templates)
//   EDGE_SHARED_SECRET — gates the endpoint (x-edge-secret header)

import { corsHeaders, json } from "../_shared/cors.ts";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");
// Currently issued Anthropic model id. `claude-opus-4-8` was a placeholder
// that would 400 at runtime — pinned to the current opus point release.
// Bump on Anthropic model refresh (see claude-api skill).
const CLAUDE_MODEL = "claude-opus-4-5";

interface Draft {
  description: string;
  responsibilities: string;
  requirements: string;
  benefits: string;
}

// ── Template fallback (no key required) ──────────────────────────────────────
function templateDraft(input: Record<string, unknown>): Draft {
  const title = String(input.title ?? "").trim() || "this role";
  const skills = Array.isArray(input.skills) ? input.skills.map(String) : [];
  const skillList = skills.length ? skills.join(", ") : "the required skills";
  return {
    description:
      `We're hiring a ${title}. You'll join a growing team and make an ` +
      `immediate impact — a great opportunity to grow your career.`,
    responsibilities:
      `Deliver high-quality work as a ${title}. Collaborate with the team. ` +
      `Use ${skillList} day to day.`,
    requirements:
      `Proven experience relevant to a ${title}. Skills: ${skillList}. ` +
      `Reliable and a good communicator.`,
    benefits: `Competitive pay. Supportive team. Room to grow.`,
  };
}

// ── Real Claude drafting ─────────────────────────────────────────────────────
const LANG: Record<string, string> = {
  uz: "Uzbek (Latin script)",
  ru: "Russian",
  en: "English",
};

// Caps on every free-text/array input reaching the model prompt — an
// authenticated caller (this function requires a Supabase JWT — see
// config.toml, it's not in the verify_jwt=false list) could otherwise still
// pump oversized payloads to run up the Anthropic bill or pad the prompt for
// injection attempts.
const MAX_TITLE_LEN = 120;
const MAX_SKILLS = 20;
const MAX_SKILL_LEN = 40;

async function claudeDraft(input: Record<string, unknown>): Promise<Draft> {
  const title = String(input.title ?? "").trim().slice(0, MAX_TITLE_LEN);
  const category = String(input.category ?? "").trim().slice(0, MAX_TITLE_LEN);
  const jobType = String(input.jobType ?? "").trim().slice(0, MAX_TITLE_LEN);
  const skills = (Array.isArray(input.skills) ? input.skills.map(String) : [])
    .slice(0, MAX_SKILLS)
    .map((s) => s.slice(0, MAX_SKILL_LEN));
  const lang = LANG[String(input.locale ?? "uz")] ?? LANG.uz;

  const facts = [
    `Job title: ${title || "(not specified)"}`,
    category && `Category: ${category}`,
    jobType && `Employment type: ${jobType}`,
    skills.length && `Key skills: ${skills.join(", ")}`,
  ].filter(Boolean).join("\n");

  const system =
    "You are a recruiting copywriter for Yollla, a blue-collar and " +
    "mass-hiring job marketplace in Uzbekistan. Write a clear, concrete, " +
    `realistic job posting in ${lang} for hourly / shift work. Keep each ` +
    "section short and practical. Do NOT invent a salary, company name, or " +
    "contact details. Do NOT state gender, age, race, religion, or " +
    "nationality requirements (it is illegal and against our policy).";

  // Force a single tool call so the model returns clean, structured sections.
  const tool = {
    name: "emit_job_post",
    description: "Return the drafted job-post sections.",
    input_schema: {
      type: "object",
      properties: {
        description: {
          type: "string",
          description: "2-4 sentence overview of the role.",
        },
        responsibilities: {
          type: "string",
          description: "What the worker does; short newline-separated lines.",
        },
        requirements: {
          type: "string",
          description: "What the worker needs; short newline-separated lines.",
        },
        benefits: {
          type: "string",
          description: "What the employer offers; short newline-separated lines.",
        },
      },
      required: ["description", "responsibilities", "requirements", "benefits"],
    },
  };

  const resp = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": ANTHROPIC_API_KEY!,
      "anthropic-version": "2023-06-01",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: CLAUDE_MODEL,
      max_tokens: 1024,
      system,
      tools: [tool],
      tool_choice: { type: "tool", name: "emit_job_post" },
      messages: [
        {
          role: "user",
          content: `Draft a job posting from these facts:\n${facts}`,
        },
      ],
    }),
  });

  if (!resp.ok) {
    throw new Error(`anthropic ${resp.status}: ${await resp.text()}`);
  }
  const data = await resp.json();
  const block = Array.isArray(data?.content)
    ? data.content.find(
      (b: Record<string, unknown>) => b?.type === "tool_use",
    )
    : null;
  const out = (block?.input ?? {}) as Partial<Draft>;
  return {
    description: String(out.description ?? ""),
    responsibilities: String(out.responsibilities ?? ""),
    requirements: String(out.requirements ?? ""),
    benefits: String(out.benefits ?? ""),
  };
}

// ── Rule-based applicant ranking (skill overlap) ─────────────────────────────
function rank(input: Record<string, unknown>) {
  const jobSkills = (Array.isArray(input.jobSkills) ? input.jobSkills : [])
    .map((s) => String(s).toLowerCase());
  const js = new Set(jobSkills);
  const applicants = Array.isArray(input.applicants) ? input.applicants : [];
  const ranked = applicants
    .map((a: Record<string, unknown>) => {
      const sk = (Array.isArray(a?.skills) ? a.skills : [])
        .map((s: unknown) => String(s).toLowerCase());
      const inter = sk.filter((s: string) => js.has(s)).length;
      const union = new Set([...jobSkills, ...sk]).size;
      return { id: String(a?.id ?? ""), score: union === 0 ? 0 : inter / union };
    })
    .sort((x, y) => y.score - x.score);
  return { ranked };
}

// ── "Am I a good match?" — seeker-facing fit assessment ──────────────────────
function matchScore(input: Record<string, unknown>) {
  const jobSkills = (Array.isArray(input.jobSkills) ? input.jobSkills : [])
    .map(String);
  const mySkills = (Array.isArray(input.mySkills) ? input.mySkills : [])
    .map(String);
  const js = jobSkills.map((s) => s.toLowerCase().trim()).filter(Boolean);
  if (js.length === 0) {
    return { score: 0, summary: "", strengths: [], gaps: [] };
  }
  const ms = new Set(mySkills.map((s) => s.toLowerCase().trim()));
  const strengths = jobSkills.filter((s) => ms.has(s.toLowerCase().trim()));
  const gaps = jobSkills.filter((s) => !ms.has(s.toLowerCase().trim()));
  return {
    score: Math.round((strengths.length / js.length) * 100),
    summary: "",
    strengths,
    gaps,
  };
}

async function claudeMatch(input: Record<string, unknown>) {
  const title = String(input.title ?? "").trim().slice(0, MAX_TITLE_LEN);
  const jobSkills = (Array.isArray(input.jobSkills) ? input.jobSkills : [])
    .map(String)
    .slice(0, MAX_SKILLS)
    .map((s) => s.slice(0, MAX_SKILL_LEN));
  const description = String(input.description ?? "").trim();
  const mySkills = (Array.isArray(input.mySkills) ? input.mySkills : [])
    .map(String)
    .slice(0, MAX_SKILLS)
    .map((s) => s.slice(0, MAX_SKILL_LEN));
  const myHeadline = String(input.myHeadline ?? "").trim().slice(0, MAX_TITLE_LEN);
  const lang = LANG[String(input.locale ?? "uz")] ?? LANG.uz;

  const facts = [
    `Job title: ${title || "(not specified)"}`,
    jobSkills.length && `Job requires: ${jobSkills.join(", ")}`,
    description && `Job description: ${description.slice(0, 1500)}`,
    myHeadline && `Candidate headline: ${myHeadline}`,
    `Candidate skills: ${mySkills.length ? mySkills.join(", ") : "(none listed)"}`,
  ].filter(Boolean).join("\n");

  const system =
    "You are a career advisor for Yollla, a blue-collar job marketplace in " +
    `Uzbekistan. Assess how well a candidate fits a job. Answer in ${lang}. Be ` +
    "honest, concise and encouraging. score = 0-100 (share of the job's needs " +
    "the candidate clearly meets). strengths = the candidate's relevant skills; " +
    "gaps = important job skills they appear to lack. Use the facts only.";

  const tool = {
    name: "emit_match",
    description: "Return the candidate-job fit assessment.",
    input_schema: {
      type: "object",
      properties: {
        score: { type: "integer", description: "0-100 fit score." },
        summary: {
          type: "string",
          description: "2-3 sentence assessment addressed to the candidate.",
        },
        strengths: { type: "array", items: { type: "string" } },
        gaps: { type: "array", items: { type: "string" } },
      },
      required: ["score", "summary", "strengths", "gaps"],
    },
  };

  const resp = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": ANTHROPIC_API_KEY!,
      "anthropic-version": "2023-06-01",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: CLAUDE_MODEL,
      max_tokens: 1024,
      system,
      tools: [tool],
      tool_choice: { type: "tool", name: "emit_match" },
      messages: [{ role: "user", content: `Assess the fit:\n${facts}` }],
    }),
  });
  if (!resp.ok) throw new Error(`anthropic ${resp.status}: ${await resp.text()}`);
  const data = await resp.json();
  const block = Array.isArray(data?.content)
    ? data.content.find((b: Record<string, unknown>) => b?.type === "tool_use")
    : null;
  const out = (block?.input ?? {}) as Record<string, unknown>;
  return {
    score: Math.max(0, Math.min(100, Number(out.score) || 0)),
    summary: String(out.summary ?? ""),
    strengths: Array.isArray(out.strengths) ? out.strengths.map(String) : [],
    gaps: Array.isArray(out.gaps) ? out.gaps.map(String) : [],
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  // Fail CLOSED — a missing EDGE_SHARED_SECRET used to leave this endpoint
  // fully open, letting anyone burn ANTHROPIC_API_KEY spend by hitting it
  // directly. Every other _shared/auth.ts-based fn already fails closed;
  // this was the outlier. If the secret isn't set the request is rejected
  // exactly as if the header didn't match, so a misconfigured deployment
  // fails loud instead of silently exposing Claude to the public internet.
  const secret = Deno.env.get("EDGE_SHARED_SECRET");
  if (!secret || req.headers.get("x-edge-secret") !== secret) {
    return json({ ok: false, error: "unauthorized" }, 401);
  }
  const body = await req.json().catch(() => ({}));
  if (body?.action === "rank") return json({ ok: true, ...rank(body) });

  if (body?.action === "match") {
    if (ANTHROPIC_API_KEY) {
      try {
        return json({ ok: true, source: "claude", ...(await claudeMatch(body)) });
      } catch (e) {
        console.error("claudeMatch failed, using rule-based:", e);
      }
    }
    return json({ ok: true, source: "rule", ...matchScore(body) });
  }

  // draft — real Claude when a key is present, templates otherwise. Any API
  // error falls back to the template so the button never dead-ends.
  if (ANTHROPIC_API_KEY) {
    try {
      return json({ ok: true, source: "claude", ...(await claudeDraft(body)) });
    } catch (e) {
      console.error("claudeDraft failed, using template:", e);
    }
  }
  return json({ ok: true, source: "template", ...templateDraft(body) });
});
