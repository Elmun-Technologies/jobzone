// generate-job-content — AI assist for employers (job-post drafting + applicant
// ranking).
//
// STUB: returns template-based drafts and rule-based (skill-overlap) ranking —
// NO external API key required. Swap the `draft`/`rank` bodies for a Claude call
// later; the request/response contract stays the same so callers don't change.
//
// Optional function secret: EDGE_SHARED_SECRET

import { corsHeaders, json } from "../_shared/cors.ts";

function draft(input: Record<string, unknown>) {
  const title = (String(input.title ?? "").trim()) || "this role";
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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  const secret = Deno.env.get("EDGE_SHARED_SECRET");
  if (secret && req.headers.get("x-edge-secret") !== secret) {
    return json({ ok: false, error: "unauthorized" }, 401);
  }
  const body = await req.json().catch(() => ({}));
  if (body?.action === "rank") return json({ ok: true, ...rank(body) });
  return json({ ok: true, ...draft(body) });
});
