"use server";

// AI helper for the résumé wizard: writes a seeker's professional summary
// ("About me") from a few notes. Uses the same GLM (Z.ai) key + dual-base
// retry + free-model default + template fallback as the post-a-job AI, so
// "Write with AI" never breaks the flow (no key / any error → a localized
// starter the seeker can edit).

export interface ResumeSummaryResult {
  ok: boolean;
  source: "glm" | "template";
  /** A key was configured but every GLM attempt failed — the client shows a
   * "used a starter, check the key" note (stays false on the no-key path). */
  fellBack?: boolean;
  debug?: string;
  summary: string;
}

const GLM_BASES = [
  "https://api.z.ai/api/paas/v4",
  "https://api.z.ai/api/coding/paas/v4",
];

const LANG: Record<string, string> = {
  uz: "Uzbek (Latin script)",
  ru: "Russian",
  en: "English",
};

const EXP_LABEL: Record<string, string> = {
  none: "no formal experience yet",
  under_1: "under 1 year of experience",
  "1_3": "1–3 years of experience",
  "3_5": "3–5 years of experience",
  "5_plus": "5+ years of experience",
};

function templateSummary(locale: string, position: string): string {
  const role = position.trim();
  if (locale === "ru") {
    return role
      ? `Ответственный специалист по направлению «${role}». Работаю аккуратно и честно, довожу задачи до результата, легко нахожу общий язык с командой. Готов(а) учиться и приступить к работе в ближайшее время.`
      : "Ответственный и исполнительный сотрудник. Работаю аккуратно, довожу задачи до результата и готов(а) быстро приступить к работе.";
  }
  if (locale === "en") {
    return role
      ? `Reliable ${role} who works carefully and honestly, sees tasks through, and gets on well with a team. Eager to learn and ready to start soon.`
      : "Reliable, diligent worker — careful with tasks, sees them through, and ready to start soon.";
  }
  return role
    ? `«${role}» yo'nalishi bo'yicha mas'uliyatli mutaxassisman. Ishni halol va tartibli bajaraman, vazifalarni oxiriga yetkazaman, jamoada yaxshi ishlayman. O'rganishga tayyorman va tez orada ishga kirisha olaman.`
    : "Mas'uliyatli va tartibli xodimman. Ishni halol bajaraman, vazifalarni oxiriga yetkazaman va tez orada ishga kirisha olaman.";
}

export async function generateResumeSummary(input: {
  position: string;
  experienceLevel?: string | null;
  city?: string | null;
  notes?: string | null;
  locale: string;
}): Promise<ResumeSummaryResult> {
  // Bound each input so one call can't be inflated into a huge-token request
  // against the shared key (the résumé wizard is behind sign-in, but bound anyway).
  const position = (input.position ?? "").slice(0, 120);
  const city = input.city?.slice(0, 80) ?? null;
  const notes = input.notes?.slice(0, 800) ?? null;
  const exp = input.experienceLevel
    ? (EXP_LABEL[input.experienceLevel] ?? null)
    : null;
  const { locale } = input;
  const key = process.env.GLM_API_KEY;

  if (!position.trim() || !key) {
    return {
      ok: true,
      source: "template",
      summary: templateSummary(locale, position),
    };
  }

  const configured = process.env.GLM_BASE_URL?.replace(/\/$/, "");
  const bases = [
    ...new Set([configured, ...GLM_BASES].filter(Boolean)),
  ] as string[];
  const model = process.env.GLM_MODEL ?? "glm-4.5-flash";
  const lang = LANG[locale] ?? LANG.uz;

  const system = `You are an expert career coach writing the "About me" summary for a candidate on Yolla, a blue-collar / mass-hiring job marketplace in Uzbekistan. Write in ${lang}, in the FIRST PERSON, warm but professional.

Rules:
- 2–4 sentences, concrete and realistic for THIS role — no vague clichés, no invented employers, certificates, or numbers not given.
- Highlight reliability, relevant skills, and readiness to start — the things a blue-collar employer actually cares about.
- Weave in the candidate's notes when given; expand shorthand into natural wording.
- Never mention gender, age, nationality, or religion. Do not invent contact details.
- Return ONLY the summary text — no preamble, no quotes, no JSON, no markdown.`;

  const user = `Desired role / position: ${position}
Experience: ${exp ?? "(not specified)"}
City: ${city || "—"}
Candidate's notes about themselves: ${notes?.trim() || "(none — infer a sensible, honest summary for this role)"}`;

  const body = JSON.stringify({
    model,
    temperature: 0.7,
    max_tokens: 500,
    messages: [
      { role: "system", content: system },
      { role: "user", content: user },
    ],
  });

  let lastReason = "unknown";
  for (const base of bases) {
    try {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), 30_000);
      const res = await fetch(`${base}/chat/completions`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${key}`,
        },
        body,
        signal: controller.signal,
      });
      clearTimeout(timer);
      if (!res.ok) {
        lastReason = `GLM ${res.status}`;
        continue;
      }
      const data = (await res.json()) as {
        choices?: { message?: { content?: string } }[];
      };
      const content = data.choices?.[0]?.message?.content?.trim();
      if (!content) {
        lastReason = "empty response";
        continue;
      }
      // Strip any stray quotes/fences the model may wrap around the text.
      const summary = content
        .replace(/^```[a-z]*\s*/i, "")
        .replace(/```\s*$/, "")
        .replace(/^["'«»]+|["'«»]+$/g, "")
        .trim();
      if (!summary) {
        lastReason = "empty after cleanup";
        continue;
      }
      return { ok: true, source: "glm", summary: summary.slice(0, 1200) };
    } catch (e) {
      lastReason = e instanceof Error ? e.message : "network error";
    }
  }

  console.error(
    "generateResumeSummary (GLM) failed on all bases, using template —",
    lastReason,
  );
  return {
    ok: true,
    source: "template",
    fellBack: true,
    debug: lastReason,
    summary: templateSummary(locale, position),
  };
}
