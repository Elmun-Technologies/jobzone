// telegram-webhook — links a Telegram chat to a Yolla profile via a
// `/start <token>` handshake, then confirms in-chat. Notification fan-out to
// Telegram is sent from here too (later); cleanly no-ops until the bot exists.
//
// Required secrets: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, TELEGRAM_BOT_TOKEN,
//                    TELEGRAM_WEBHOOK_SECRET (also set as the `secret_token` on
//                    the bot's setWebhook call — see docs/go-live-checklist.md)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { corsHeaders, json } from "../_shared/cors.ts";
import { requireTelegramSecret } from "../_shared/auth.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  // Telegram sends no Supabase JWT; authenticity is the secret_token echoed
  // back on every update. Fail closed.
  const denied = requireTelegramSecret(req);
  if (denied) return denied;

  const update = await req.json().catch(() => ({}));
  const msg = update?.message;
  const text: string = msg?.text ?? "";
  const chatId = msg?.chat?.id;
  if (!chatId || !text.startsWith("/start")) return json({ ok: true });

  const token = text.split(" ")[1]?.trim();
  if (!token) return json({ ok: true });

  const supa = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data: row } = await supa
    .from("telegram_link_tokens")
    .select("profile_id, expires_at")
    .eq("token", token)
    .maybeSingle();
  if (!row || new Date(row.expires_at) < new Date()) return json({ ok: true });

  await supa.from("telegram_links").upsert({
    profile_id: row.profile_id,
    telegram_chat_id: String(chatId),
    username: msg?.chat?.username ?? null,
  });
  await supa.from("telegram_link_tokens").delete().eq("token", token);

  const botToken = Deno.env.get("TELEGRAM_BOT_TOKEN");
  if (botToken) {
    await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        chat_id: chatId,
        text: "✅ Yolla connected. You'll get job & applicant alerts here.",
      }),
    }).catch(() => {});
  }
  return json({ ok: true });
});
