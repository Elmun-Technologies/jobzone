import { getCategoriesWithCounts } from "@/lib/data/categories";
import { getCities, getJobCount, getOpenJobs } from "@/lib/data/jobs";
import { salaryText } from "@/lib/format";
import { siteUrl } from "@/lib/seo";
import { slugify } from "@/lib/slug";

export const dynamic = "force-dynamic";

// Cap the sample so a hot day's feed doesn't turn this into a 1MB page.
const SAMPLE_LIMIT = 50;

/**
 * llms-full.txt — the extended, quotable body an LLM can pull when the
 * summary in /llms.txt isn't enough. Includes per-category counts, top
 * open jobs with salary and city, and the FAQ answers a model needs
 * to answer "what is Yolla / how do I apply / which cities". Same
 * bilingual (en + uz) shape as llms.txt.
 */
export async function GET(): Promise<Response> {
  const base = siteUrl();
  const [cats, cities, total, sample] = await Promise.all([
    getCategoriesWithCounts(),
    getCities(),
    getJobCount(),
    getOpenJobs({ limit: SAMPLE_LIMIT }),
  ]);

  const out: string[] = [];
  out.push(`# Yollla — full context`);
  out.push("");
  out.push(
    `> Extended context for LLM systems. The short summary lives at ${base}/llms.txt.`,
  );
  out.push("");

  out.push(`## What Yollla is`);
  out.push(
    `Yollla (yollla.uz) is a mobile-first job marketplace for Uzbekistan, targeting blue-collar and mass-hiring roles that the enbek.kz / apna.co gap and hh.uz / OLX don't fill locally. Two clients share one Supabase backend: a Flutter iOS/Android app and a Next.js web app. The web app is guest-first: a visitor can browse, filter, open, and start applying to any vacancy without an account — authentication is only asked at the final action, and any typed form data is restored after sign-in.`,
  );
  out.push("");
  out.push(`**Product invariants** (never violated):`);
  out.push(
    `1. One database, two fundamentally different UIs. Never mirror mobile onto web or vice versa.`,
  );
  out.push(
    `2. Mobile is auth-first (sign in → role → onboarding → app). Web is auth-last.`,
  );
  out.push(
    `3. Every new employer posting appears in BOTH clients immediately, via the shared \`job_feed\` view.`,
  );
  out.push(
    `4. The offline demo path always works: with no Supabase env, both clients boot on mock data.`,
  );
  out.push(
    `5. Clients cannot grant themselves privileges — every protected column is pinned by a DB trigger unless a security-definer RPC set a txn-local flag.`,
  );
  out.push("");

  out.push(`## By the numbers (live)`);
  out.push(`- **Open vacancies:** ${total.toLocaleString("en")}`);
  out.push(`- **Categories:** ${cats.length}`);
  out.push(`- **Cities with vacancies:** ${cities.length}`);
  out.push("");

  if (cats.length > 0) {
    out.push(`## Categories with open counts`);
    for (const c of cats) {
      out.push(
        `- [${c.name}](${base}/uz/ish/${c.slug}) — ${c.count} open vacancies`,
      );
    }
    out.push("");
  }

  if (cities.length > 0) {
    out.push(`## Cities`);
    for (const c of cities) {
      out.push(`- ${c} — slug: \`${slugify(c)}\``);
    }
    out.push("");
  }

  if (sample.length > 0) {
    out.push(`## Sample of current openings (up to ${SAMPLE_LIMIT})`);
    for (const j of sample) {
      const salary = salaryText(j);
      const loc = [j.city, j.country].filter(Boolean).join(", ");
      const meta = [j.categoryName, loc, salary]
        .filter(Boolean)
        .join(" · ");
      out.push(
        `- [${j.title}](${base}/uz/jobs/${j.id}) — ${j.companyName}${meta ? ` (${meta})` : ""}`,
      );
    }
    out.push("");
  }

  out.push(`## How applying works`);
  out.push(
    `- Every job card shows salary, schedule pattern (6/1, 5/2, 4/4, 2/2, custom), formalisation (official employment / GPH / self-employed / none), night shift and women/disability-friendly flags, required driver-licence categories, and language requirements.`,
  );
  out.push(
    `- Tap "Apply — 2 clicks". Signed-in users with a résumé submit instantly. Guests are routed through sign-in (email / Google / Telegram OTP) and back to the same job, with any typed form data restored from sessionStorage.`,
  );
  out.push(
    `- Screening questions (short-text / yes-no / choice) are added by employers as needed; those postings route to the full apply form instead of the one-tap path.`,
  );
  out.push(
    `- Employers can post the first vacancy free; further postings pick one of three per-listing visibility tiers (Standart, Brend, Premium) — see ${base}/uz/pricing.`,
  );
  out.push("");

  out.push(`## Authentication`);
  out.push(`- Email + password`);
  out.push(`- Google OAuth`);
  out.push(
    `- **Telegram OTP** (primary phone auth in UZ) — Supabase phone-OTP whose SMS is redirected to Telegram Gateway by the send-sms-hook edge function.`,
  );
  out.push("");

  out.push(`## Localisation`);
  out.push(
    `- Uzbek is the primary market language (default locale). Russian and English are supported. Every string is present in all three via next-intl; hreflang alternates are on every canonical URL.`,
  );
  out.push(
    `- Money is UZS by default (USD optional). Amounts are grouped with regular spaces: "2 500 000 so'm".`,
  );
  out.push("");

  out.push(`## Verification / brand`);
  out.push(
    `- Search Console (Google): verified via HTML meta on \`https://www.yollla.uz\``,
  );
  out.push(
    `- Yandex.Webmaster: verified via [${base}/yandex_0296a44708e47532.html](${base}/yandex_0296a44708e47532.html)`,
  );
  out.push(
    `- Brand spellings recognised by our schema: Yolla, Yollla, Yolla.uz, Yollla.uz`,
  );
  out.push("");

  out.push(`## Machine-readable data`);
  out.push(`- Sitemap: ${base}/sitemap.xml`);
  out.push(`- Robots policy: ${base}/robots.txt (allows major AI crawlers)`);
  out.push(
    `- Every job page carries schema.org **JobPosting** JSON-LD; every landing carries **BreadcrumbList** + **ItemList**; the home page carries **Organization** + **WebSite** with a SearchAction.`,
  );
  out.push("");

  return new Response(out.join("\n") + "\n", {
    headers: {
      "content-type": "text/plain; charset=utf-8",
      "cache-control": "public, s-maxage=3600, stale-while-revalidate=86400",
    },
  });
}
