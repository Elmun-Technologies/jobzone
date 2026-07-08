"use server";

// AI draft for the post-a-job wizard. Uses the employer's GLM (Z.ai) key over
// its OpenAI-compatible chat endpoint; with no key (or on any error) it falls
// back to a localized template so "Fill with AI" never breaks the flow.
//
// Defaults to a FREE model (glm-4.5-flash) so a free-tier / coding-plan key
// works out of the box — a paid-only model would 400 on those keys and quietly
// drop everyone to the shallow template. Override with GLM_MODEL if desired.

export interface JobDraftContent {
  ok: boolean;
  source: "glm" | "template";
  /** True when a key WAS configured but every GLM attempt failed — the client
   * shows a "used template, check the key/URL" note (vs. the silent no-key
   * path, where this stays false). */
  fellBack?: boolean;
  /** Short reason for the fallback (e.g. "GLM 401"), surfaced to the employer. */
  debug?: string;
  description: string;
  responsibilities: string;
  requirements: string;
  benefits: string;
  // Structured fields the model may infer from the notes — applied to the
  // form only when the employer hasn't set them, and only if valid.
  salaryMin?: number | null;
  salaryMax?: number | null;
  jobType?: string | null;
  experienceLevel?: string | null;
  schedulePattern?: string | null;
}

// Z.ai exposes two OpenAI-compatible bases: the general one and a separate
// Coding-Plan one. A key issued for one base 401/404s on the other, so we try
// the configured base first (if any), then both defaults — this makes a
// Coding-Plan key work without the employer having to set GLM_BASE_URL.
const GLM_BASES = [
  "https://api.z.ai/api/paas/v4",
  "https://api.z.ai/api/coding/paas/v4",
];

const LANG: Record<string, string> = {
  uz: "Uzbek (Latin script)",
  ru: "Russian",
  en: "English",
};

const JOB_TYPES = [
  "full_time",
  "part_time",
  "contract",
  "temporary",
  "internship",
  "rotational",
];
const EXPERIENCE = ["entry", "mid", "senior", "lead"];
const SCHEDULES = ["5_2", "6_1", "4_4", "2_2", "custom"];

function templateDraft(locale: string): Omit<JobDraftContent, "ok" | "source"> {
  if (locale === "ru") {
    return {
      description:
        "Мы ищем ответственного сотрудника. Ждём честного, аккуратного кандидата, заинтересованного в работе.",
      responsibilities:
        "Выполнение ежедневных задач\nРабота в команде\nСоблюдение качества и сроков",
      requirements:
        "Соответствующий опыт (желательно)\nОтветственность и честность\nУмение работать в команде",
      benefits: "Стабильная зарплата\nДружный коллектив\nВозможность роста",
    };
  }
  if (locale === "en") {
    return {
      description:
        "We're looking for a reliable team member — an honest, diligent candidate who cares about the work.",
      responsibilities:
        "Handle day-to-day tasks\nWork as part of the team\nMeet quality and deadlines",
      requirements:
        "Relevant experience (a plus)\nResponsibility and honesty\nAbility to work in a team",
      benefits: "Stable pay\nFriendly team\nRoom to grow",
    };
  }
  return {
    description:
      "Mas'uliyatli xodim izlaymiz. Halol, tartibli va o'z ishiga qiziqqan nomzodni kutamiz.",
    responsibilities:
      "Kundalik vazifalarni bajarish\nJamoada ishlash\nSifat va muddatga rioya qilish",
    requirements:
      "Tegishli tajriba (afzallik)\nMas'uliyat va halollik\nJamoada ishlay olish",
    benefits: "Barqaror ish haqi\nDo'stona jamoa\nO'sish imkoniyati",
  };
}

/** Pull the first {...} JSON object out of a model reply, tolerating ```json
 * fences and any prose the model wraps around it. */
function parseJson(text: string): Record<string, unknown> {
  const cleaned = text
    .trim()
    .replace(/^```(?:json)?\s*/i, "")
    .replace(/```\s*$/, "")
    .trim();
  try {
    return JSON.parse(cleaned) as Record<string, unknown>;
  } catch {
    const start = cleaned.indexOf("{");
    const end = cleaned.lastIndexOf("}");
    if (start !== -1 && end > start) {
      return JSON.parse(cleaned.slice(start, end + 1)) as Record<
        string,
        unknown
      >;
    }
    throw new Error("no json");
  }
}

export async function generateJobContent(input: {
  title: string;
  category?: string | null;
  notes?: string | null;
  locale: string;
}): Promise<JobDraftContent> {
  // Cap each input so one call can't be inflated into a huge-token request
  // against the shared GLM key (bounded cost per call; the post-job page is
  // guest-usable by design, so we bound rather than gate on auth).
  const title = (input.title ?? "").slice(0, 120);
  const category = input.category?.slice(0, 80) ?? null;
  const notes = input.notes?.slice(0, 800) ?? null;
  const { locale } = input;
  const key = process.env.GLM_API_KEY;
  const tmpl = templateDraft(locale);

  if (!title.trim() || !key) {
    return { ok: true, source: "template", ...tmpl };
  }

  // Try the configured base (if any) first, then both known defaults — de-duped.
  const configured = process.env.GLM_BASE_URL?.replace(/\/$/, "");
  const bases = [
    ...new Set([configured, ...GLM_BASES].filter(Boolean)),
  ] as string[];
  const model = process.env.GLM_MODEL ?? "glm-4.5-flash";
  const lang = LANG[locale] ?? LANG.uz;

  const system = `You are an expert HR copywriter for Yolla, a blue-collar / mass-hiring job marketplace in Uzbekistan. Write a complete, professional, and specific job posting in ${lang}.

Rules:
- Be concrete and realistic for THIS exact role — no filler, no vague "responsible employee" clichés. Mention real day-to-day tasks, tools, and expectations a candidate for this job would actually see.
- "description": 3–5 full sentences that sell the role and the workplace warmly and honestly.
- "responsibilities", "requirements", "benefits": each 4–6 specific, concrete lines, one per line (newline-separated, no bullet characters).
- Weave in the employer's notes below when given; expand shorthand into full professional wording.
- If the notes (or the role) clearly imply a salary range, employment type, experience level, or schedule, fill the matching structured field; otherwise leave it null. Never guess wildly.
- Do NOT invent company names, phone numbers, or any discriminatory requirement (gender, age, nationality, religion).

Allowed values — jobType: ${JOB_TYPES.join(", ")}; experienceLevel: ${EXPERIENCE.join(", ")}; schedulePattern: ${SCHEDULES.join(", ")}. salaryMin/salaryMax are monthly UZS integers (no separators) or null.

Return ONLY a JSON object with exactly these keys: description, responsibilities, requirements, benefits, salaryMin, salaryMax, jobType, experienceLevel, schedulePattern.`;

  const user = `Job title: ${title}
Category: ${category || "—"}
Employer's key requirements / notes: ${notes?.trim() || "(none given — infer sensible defaults for this role)"}`;

  const body = JSON.stringify({
    model,
    temperature: 0.7,
    max_tokens: 2200,
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
        // 401/403 = wrong key for this base; 404 = wrong base → try the next.
        lastReason = `GLM ${res.status}`;
        continue;
      }
      const data = (await res.json()) as {
        choices?: { message?: { content?: string } }[];
      };
      const content = data.choices?.[0]?.message?.content;
      if (!content) {
        lastReason = "empty response";
        continue;
      }
      const j = parseJson(content);

      const str = (k: string, fb: string) =>
        typeof j[k] === "string" && (j[k] as string).trim()
          ? (j[k] as string).trim()
          : fb;
      const num = (k: string): number | null => {
        const v = j[k];
        const n = typeof v === "string" ? Number(v.replace(/\s+/g, "")) : v;
        return typeof n === "number" && Number.isFinite(n) && n > 0
          ? Math.round(n)
          : null;
      };
      const enumOf = (k: string, allowed: string[]): string | null => {
        const v = j[k];
        return typeof v === "string" && allowed.includes(v) ? v : null;
      };

      return {
        ok: true,
        source: "glm",
        description: str("description", tmpl.description),
        responsibilities: str("responsibilities", tmpl.responsibilities),
        requirements: str("requirements", tmpl.requirements),
        benefits: str("benefits", tmpl.benefits),
        salaryMin: num("salaryMin"),
        salaryMax: num("salaryMax"),
        jobType: enumOf("jobType", JOB_TYPES),
        experienceLevel: enumOf("experienceLevel", EXPERIENCE),
        schedulePattern: enumOf("schedulePattern", SCHEDULES),
      };
    } catch (e) {
      lastReason = e instanceof Error ? e.message : "network error";
    }
  }

  console.error(
    "generateJobContent (GLM) failed on all bases, using template —",
    lastReason,
  );
  return {
    ok: true,
    source: "template",
    fellBack: true,
    debug: lastReason,
    ...tmpl,
  };
}
