// telegram-channel-post — the platform's self-marketing loop: when a job
// becomes 'open' the `trg_telegram_channel_dispatch` trigger (migration 0058)
// pg_net-POSTs { job_id } here. This looks up the job's category + region,
// finds the matching Telegram channel (falling back to that category's
// catch-all channel, region = null), and posts a formatted card — the
// category's static banner image if the CMS has one, else a text-only
// message — with a link back to the job on the web (auth-last, no app
// install required to view/apply). The bot must already be an admin of every
// target channel; channels are mapped in the admin CMS (telegram_channels).
//
// Required secrets: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, TELEGRAM_BOT_TOKEN,
//                    EDGE_SHARED_SECRET
// Optional: WEBAPP_URL (default https://yollla.uz) — base URL for the job link

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { corsHeaders, json } from "../_shared/cors.ts";
import { requireEdgeSecret } from "../_shared/auth.ts";

function groupDigits(n: number): string {
  return Math.round(n)
    .toString()
    .replace(/\B(?=(\d{3})+(?!\d))/g, " ");
}

function salaryText(
  min: number | null,
  max: number | null,
  currency: string,
): string | null {
  if (min == null && max == null) return null;
  const cur = currency.toUpperCase() === "USD" ? "$" : "so'm";
  const isUsd = cur === "$";
  const fmt = (n: number) => (isUsd ? `${cur}${groupDigits(n)}` : groupDigits(n));
  let amount: string;
  if (min != null && max != null) amount = `${fmt(min)} - ${fmt(max)}`;
  else if (min != null) amount = `${fmt(min)}+`;
  else amount = fmt(max!);
  return isUsd ? amount : `${amount} ${cur}`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Server-to-server only (the jobs trigger). Fail closed.
  const denied = requireEdgeSecret(req);
  if (denied) return denied;

  const botToken = Deno.env.get("TELEGRAM_BOT_TOKEN");
  if (!botToken) return json({ ok: true, skipped: "no bot token" });

  const payload = await req.json().catch(() => ({}));
  const jobId = payload?.job_id ?? payload?.record?.id;
  if (!jobId) return json({ ok: false, error: "missing job_id" }, 400);

  const supa = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: job } = await supa
    .from("jobs")
    .select("id, title, region, district, city, salary_min, salary_max, currency, company_id, category_id, status")
    .eq("id", jobId)
    .maybeSingle();
  if (!job || job.status !== "open" || !job.category_id) {
    return json({ ok: true, skipped: "job not open" });
  }

  const [{ data: category }, { data: company }, { data: channels }] = await Promise.all([
    supa.from("job_categories").select("name, banner_url").eq("id", job.category_id).maybeSingle(),
    supa.from("companies").select("name").eq("id", job.company_id).maybeSingle(),
    supa
      .from("telegram_channels")
      .select("chat_id, region")
      .eq("category_id", job.category_id)
      .eq("is_active", true),
  ]);

  const exact = (channels ?? []).filter((c) => c.region === job.region);
  const target = exact.length > 0 ? exact : (channels ?? []).filter((c) => c.region === null);
  if (target.length === 0) {
    return json({ ok: true, skipped: "no channel mapped" });
  }

  const webappUrl = Deno.env.get("WEBAPP_URL") ?? "https://yollla.uz";
  const jobUrl = `${webappUrl}/uz/jobs/${job.id}`;
  const salary = salaryText(job.salary_min, job.salary_max, job.currency ?? "UZS");
  const location = [job.region, job.district ?? job.city].filter(Boolean).join(", ");

  const lines = [
    `🆕 *${job.title}*`,
    company?.name ? `🏢 ${company.name}` : null,
    location ? `📍 ${location}` : null,
    salary ? `💰 ${salary}` : null,
    "",
    "👉 Ariza qoldirish uchun havolani bosing:",
  ].filter((l): l is string => l !== null);
  const caption = lines.join("\n");

  const replyMarkup = {
    inline_keyboard: [[{ text: "📲 Ariza qoldirish", url: jobUrl }]],
  };

  let sent = 0;
  for (const channel of target) {
    const method = category?.banner_url ? "sendPhoto" : "sendMessage";
    const body: Record<string, unknown> = {
      chat_id: channel.chat_id,
      parse_mode: "Markdown",
      reply_markup: replyMarkup,
    };
    if (category?.banner_url) {
      body.photo = category.banner_url;
      body.caption = caption;
    } else {
      body.text = caption;
    }
    const r = await fetch(`https://api.telegram.org/bot${botToken}/${method}`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(body),
    }).catch(() => null);
    if (r && r.ok) sent++;
  }

  return json({ ok: true, sent, matched: target.length });
});
