// saved-search-alerts — the alert tick. Turns the two things a seeker can save
// into notifications, then mails them as one digest per person.
//
// 1. run_saved_search_alerts()   (0036/0084) — new open jobs matching a saved
//    search's keywords + city, since that search's watermark.
// 2. run_company_follow_alerts() (0084)      — new open jobs from a company the
//    seeker follows, since that follow's watermark.
//    Both insert `job_match` notifications tagged `data.alert = true`; the
//    notifications AFTER-INSERT trigger (0026) fans them out to in-app +
//    Telegram + push, honoring push_job_match.
// 3. The digest — every alert notification not yet emailed is grouped by
//    recipient into ONE branded email in their language, honoring
//    email_job_match, then marked `data.emailed = true` so it can never be
//    mailed twice. One email per run beats one per vacancy: five matches at
//    03:00 must not be five 03:00 emails.
//
// This is the secret-gated HTTP entry point a scheduler invokes (Supabase cron,
// or pg_cron + pg_net). The matching + watermark bookkeeping all live in SQL,
// so this stays thin and idempotent.
//
// Required secrets: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, EDGE_SHARED_SECRET
// Optional: RESEND_API_KEY + EMAIL_FROM (without them step 3 is a no-op)

import {
  createClient,
  SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { corsHeaders, json } from "../_shared/cors.ts";
import { requireEdgeSecret } from "../_shared/auth.ts";
import {
  deliver,
  emailConfigured,
  linksFor,
  loadRecipient,
} from "../_shared/email.ts";
import {
  alertReason,
  jobAlertEmail,
  type JobItem,
} from "../_shared/email-templates.ts";

// Rows older than this were either already handled or predate the email
// channel; they must never become a surprise backlog blast the first time a
// provider key is configured.
const MAX_AGE_MS = 24 * 60 * 60 * 1000;
// Bounds one invocation's work; whatever is left is picked up by the next tick.
const MAX_ROWS = 2000;
const MAX_RECIPIENTS = 300;

interface AlertRow {
  id: string;
  recipient_id: string;
  title: string;
  body: string | null;
  data: Record<string, unknown>;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Server-to-server only (scheduler / cron). Fail closed.
  const denied = requireEdgeSecret(req);
  if (denied) return denied;

  const supa = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: searchCount, error } = await supa.rpc(
    "run_saved_search_alerts",
  );
  if (error) return json({ ok: false, error: error.message }, 500);

  // A followed company posting is the same promise as a saved search matching,
  // so one tick covers both. A failure here must not lose the count above.
  const { data: followCount, error: followError } = await supa.rpc(
    "run_company_follow_alerts",
  );
  if (followError) console.error("company follow alerts", followError.message);

  const emails = await sendDigests(supa);

  return json({
    ok: true,
    notified: typeof searchCount === "number" ? searchCount : 0,
    followed: typeof followCount === "number" ? followCount : 0,
    emails,
  });
});

/** Groups every un-emailed alert notification into one digest per recipient. */
async function sendDigests(supa: SupabaseClient): Promise<number> {
  if (!emailConfigured()) return 0;

  const since = new Date(Date.now() - MAX_AGE_MS).toISOString();
  const { data, error } = await supa
    .from("notifications")
    .select("id, recipient_id, title, body, data")
    .eq("type", "job_match")
    .eq("data->>alert", "true")
    .is("data->>emailed", null)
    .gte("created_at", since)
    .order("created_at", { ascending: true })
    .limit(MAX_ROWS);
  if (error) {
    console.error("digest query failed", error.message);
    return 0;
  }

  const rows = (data ?? []) as AlertRow[];
  if (rows.length === 0) return 0;

  const byRecipient = new Map<string, AlertRow[]>();
  for (const row of rows) {
    const list = byRecipient.get(row.recipient_id) ?? [];
    list.push(row);
    byRecipient.set(row.recipient_id, list);
  }

  let sent = 0;
  let processed = 0;
  for (const [recipientId, group] of byRecipient) {
    if (processed >= MAX_RECIPIENTS) break;
    processed++;
    try {
      if (await sendDigest(supa, recipientId, group)) sent++;
    } catch (e) {
      // One bad recipient must not stop the rest of the run.
      console.error("digest failed", recipientId, String(e).slice(0, 200));
    }
  }
  if (byRecipient.size > MAX_RECIPIENTS) {
    console.log(
      `digest: ${
        byRecipient.size - MAX_RECIPIENTS
      } recipients deferred to the next run`,
    );
  }
  return sent;
}

async function sendDigest(
  supa: SupabaseClient,
  recipientId: string,
  group: AlertRow[],
): Promise<boolean> {
  const ids = group.map((r) => r.id);
  const recipient = await loadRecipient(supa, recipientId);

  // Opted out, or nowhere to send: mark the rows handled so the query stops
  // re-examining them every tick. The in-app notification already landed.
  if (!recipient.email || recipient.prefs.email_job_match === false) {
    await markEmailed(supa, ids);
    return false;
  }

  const seen = new Set<string>();
  const jobs: JobItem[] = [];
  const reasons: string[] = [];
  for (const row of group) {
    const data = row.data ?? {};
    const jobId = typeof data.job_id === "string" ? data.job_id : undefined;
    const company = typeof data.company === "string" ? data.company : null;
    const source = typeof data.source === "string" ? data.source : null;
    const reason = alertReason(
      recipient.locale,
      source,
      source === "company_follow"
        ? company
        : typeof data.search_name === "string"
        ? data.search_name
        : null,
    );
    if (reason && !reasons.includes(reason)) reasons.push(reason);

    // A job can match a saved search *and* a followed company; one card each.
    const key = jobId ?? `${row.title}|${company ?? ""}`;
    if (seen.has(key)) continue;
    seen.add(key);
    jobs.push({
      id: jobId,
      title: row.title,
      company,
      city: typeof data.city === "string" ? data.city : null,
      reason,
    });
  }

  const content = jobAlertEmail(
    recipient.locale,
    { jobs, reasons, total: jobs.length },
    linksFor(recipient.prefs.unsubscribe_token, recipient.locale),
  );

  const result = await deliver(supa, {
    recipient,
    content,
    kind: "job_alert",
    scope: "job_match",
  });

  // Mark on anything but a hard failure, so a provider outage is retried on
  // the next tick (inside the 24h window) instead of being lost.
  if (result.status !== "failed") await markEmailed(supa, ids);
  return result.status === "sent";
}

async function markEmailed(supa: SupabaseClient, ids: string[]): Promise<void> {
  if (ids.length === 0) return;
  const { error } = await supa.rpc("mark_alert_notifications_emailed", {
    p_ids: ids,
  });
  if (error) console.error("mark emailed failed", error.message);
}
