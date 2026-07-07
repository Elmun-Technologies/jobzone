"use server";

// AI draft for the post-a-job wizard. Uses the employer's GLM (Z.ai) key over
// its OpenAI-compatible chat endpoint; with no key (or on any error) it falls
// back to a localized template so "Fill with AI" never breaks the flow.

export interface JobDraftContent {
  ok: boolean;
  source: "glm" | "template";
  description: string;
  responsibilities: string;
  requirements: string;
  benefits: string;
}

const LANG: Record<string, string> = {
  uz: "Uzbek (Latin script)",
  ru: "Russian",
  en: "English",
};

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

/** Strip ```json fences some models wrap around JSON, then parse. */
function parseJson(text: string): Record<string, unknown> {
  const cleaned = text
    .trim()
    .replace(/^```(?:json)?\s*/i, "")
    .replace(/```\s*$/, "")
    .trim();
  return JSON.parse(cleaned) as Record<string, unknown>;
}

export async function generateJobContent(input: {
  title: string;
  category?: string | null;
  locale: string;
}): Promise<JobDraftContent> {
  const { title, category, locale } = input;
  const key = process.env.GLM_API_KEY;
  const tmpl = templateDraft(locale);

  if (!title.trim() || !key) {
    return { ok: true, source: "template", ...tmpl };
  }

  const base = (
    process.env.GLM_BASE_URL ?? "https://api.z.ai/api/paas/v4"
  ).replace(/\/$/, "");
  const model = process.env.GLM_MODEL ?? "glm-4.6";
  const lang = LANG[locale] ?? LANG.uz;

  const system = `You write concise, honest job postings for a blue-collar / mass-hiring job marketplace in Uzbekistan. Write in ${lang}. From the job title and category, produce: a short "description" (2-4 sentences), "responsibilities", "requirements" and "benefits" (each a few short newline-separated lines). Do NOT invent salary, phone numbers, company names, or any discriminatory requirement (gender, age, nationality, religion). Keep it realistic and welcoming. Return ONLY a JSON object with keys description, responsibilities, requirements, benefits.`;
  const user = `Title: ${title}\nCategory: ${category || "—"}`;

  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 20_000);
    const res = await fetch(`${base}/chat/completions`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${key}`,
      },
      body: JSON.stringify({
        model,
        temperature: 0.6,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: system },
          { role: "user", content: user },
        ],
      }),
      signal: controller.signal,
    });
    clearTimeout(timer);
    if (!res.ok) throw new Error(`GLM ${res.status}`);
    const data = (await res.json()) as {
      choices?: { message?: { content?: string } }[];
    };
    const content = data.choices?.[0]?.message?.content;
    if (!content) throw new Error("empty");
    const j = parseJson(content);
    const str = (k: string, fb: string) =>
      typeof j[k] === "string" && (j[k] as string).trim()
        ? (j[k] as string).trim()
        : fb;
    return {
      ok: true,
      source: "glm",
      description: str("description", tmpl.description),
      responsibilities: str("responsibilities", tmpl.responsibilities),
      requirements: str("requirements", tmpl.requirements),
      benefits: str("benefits", tmpl.benefits),
    };
  } catch (e) {
    console.error("generateJobContent (GLM) failed, using template", e);
    return { ok: true, source: "template", ...tmpl };
  }
}
