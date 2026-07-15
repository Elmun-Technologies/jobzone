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

// A fill-in-the-[brackets] starter (used when GLM is off) — the seeker replaces
// the [placeholders] with their real facts, which keeps the résumé honest.
function templateSummary(locale: string, position: string): string {
  const role = position.trim();
  if (locale === "ru") {
    return `Ответственный ${role || "[должность]"} с опытом [сколько лет] лет. Владею навыками [ключевые навыки], имею опыт [где работал / что делал] и достиг [ваше достижение]. Работаю честно, довожу задачи до результата и готов(а) приступить [когда].`;
  }
  if (locale === "en") {
    return `Reliable ${role || "[position]"} with [how many] years of experience. Skilled in [key skills], experienced at [where you worked / what you did], and achieved [your achievement]. I work honestly, see tasks through, and can start [when].`;
  }
  return `[Necha] yillik tajribaga ega mas'uliyatli ${role || "[lavozim]"}man. [Asosiy ko'nikmalar] bo'yicha ishlayman, [oldingi ish joyi / nima qilganim]da tajriba orttirganman va [yutug'im]ga erishganman. Halol ishlayman, vazifalarni oxiriga yetkazaman va [qachon] ishga kirisha olaman.`;
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

  const system = `You are an expert career coach writing an "About me" TEMPLATE for a candidate on Yollla, a blue-collar / mass-hiring job marketplace in Uzbekistan. Write in ${lang}, first person, warm but professional.

This is a FILL-IN-THE-BLANK template the candidate personalizes with their REAL facts — that's the whole point (it prevents fake AI résumés). So:
- Write 2–4 natural sentences, but leave 3–6 of the SPECIFIC personal details as [bracketed placeholders] written in ${lang} — e.g. the years of experience, the key skills, a notable achievement, a previous workplace. Use square brackets [ ].
- The connecting prose must be complete and read well; only the personal specifics are bracketed.
- Never invent employers, certificates, or numbers — that is exactly what the [brackets] are for.
- When the candidate gave notes, use them to FILL some brackets with real content instead of leaving them blank.
- Never mention gender, age, nationality, or religion. No contact details.
- Return ONLY the template text — no preamble, no quotes, no JSON, no markdown.`;

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
