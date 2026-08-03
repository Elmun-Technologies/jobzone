# Yolla — Go-Live Checklist

The mobile app and web app are feature-complete and run **offline / gracefully
degraded** with no backend. Going live is an **ops exercise**, not a code one:
provision the Supabase backend, deploy the Edge Functions, set the secrets, and
schedule the two cron jobs below. Nothing here needs a code change.

Work top-to-bottom; each section notes how to verify it.

---

## 1. Database — apply migrations

```bash
supabase db push        # applies every migration through 0084
```

> ⚠️ **If you already ran `db push` before this checklist mentioned 0074:**
> re-run it. `0074_telegram_gateway_api_host.sql` fixes a silent bug where
> Telegram OTP codes were posted to `gateway.telegram.org` (the marketing
> site, which answers any path with HTML + `200 OK`) instead of the actual
> API host `gatewayapi.telegram.org` — so every OTP request looked like it
> succeeded while no code was ever sent. Re-verify per the migration's own
> comment: request a code, then
> `select created, status_code, content from net._http_response order by created desc limit 1;`
> — a working call returns JSON, not HTML.

> Note: the live DB is behind — it has 0065 (security_hardening) and 0067
> recorded but is missing 0063, 0064, 0066 and everything from 0068 on. A
> single `db push` applies all the un-recorded ones in version order, so a
> later migration never runs before the one it depends on. The old duplicate
> `0065_rahmat_provider` was renumbered to `0072` so it actually applies (two
> files shared version 0065, so it was silently skipped).

> ⚠️ **Two more duplicate versions were found and renumbered — re-run
> `db push`.** `0070` was shared by `account_deletion` and `scale_indexes`, and
> `0078` by `notify_applicants_on_close` and `resume_positions_and_location`.
> The version is the primary key of `supabase_migrations.schema_migrations`, so
> in each pair only the alphabetically-first file was ever recorded and the
> other was **silently skipped** — exactly the 0065 failure above, twice more.
> They are now `0081_scale_indexes.sql` and
> `0082_resume_positions_and_location.sql`. Both are written with
> `if not exists` / `create or replace` throughout, so re-applying them costs
> nothing if they somehow did land. Verify after the push:
>
> ```sql
> select indexname from pg_indexes where indexname = 'jobs_open_feed_idx';
> select column_name from information_schema.columns
>  where table_name = 'profiles' and column_name = 'desired_positions';
> ```
>
> Both must return one row. `scripts/check-migrations.sh` (run by CI on every
> PR) now blocks a duplicate version from being merged again.

Most recent, most likely un-applied:

| Migration | Adds |
|---|---|
| `0035_saved_searches` | `saved_searches` table (owner-scoped) |
| `0036_saved_search_alerts` | `last_alerted_at` watermark + `run_saved_search_alerts()` + `publish_due_jobs()` posted_at fix |
| `0044_profile_summary` / `0046_summary_ai_flag` | AI-assisted résumé "About me" + honesty flag |
| `0047_applicant_resume_access` | `is_job_owner`-gated view so an employer can read an applicant's résumé fields |
| `0048_applicant_job_status` | keeps a seeker's application to a since-closed job (e.g. hired) visible instead of dropped |
| `0049_resume_subtables_lockdown` | closes a pre-existing gap — résumé sub-tables (experiences/educations/certifications/skills) were readable by any signed-in user; now owner or a recruiter with a real relationship only |
| `0050_recommended_candidates` / `0051_recommended_jobs` | the two-way match: employer sees candidates for a new posting, seeker sees jobs matched to their résumé (same scoring, one shared algorithm per side) |
| `0052_dismissed_jobs` | lets a seeker archive a job out of their browse feed |
| `0073_rls_hardening` | closes two residual RLS gaps: an applicant could forge their own application's initial status, and a sender could move their own message into a conversation they're not a member of |
| `0074_telegram_gateway_api_host` | fixes the silent Telegram OTP failure above — **required for OTP sign-in to work at all** |
| `0084_email_channel` | the email channel: per-category email switches + unsubscribe token, `email_deliveries` send log, `set_email_pref_by_token()`, alert payloads for the digest, `run_company_follow_alerts()`, welcome-mail triggers on `auth.users`, `admin_broadcast(… p_send_email)` |
| `0075_listing_tier_upgrade` | lets an employer buy a higher tier for a vacancy that is already live (until this, `create_listing_order` accepted drafts only, so the web "Reklama" page on every open vacancy could sell nothing) |

**Verify:** `select last_alerted_at from saved_searches limit 1;` resolves, and
`select count(*) from job_feed;` returns only open, non-expired jobs.

---

## 2. Secrets

Set with `supabase secrets set NAME=…` (values are yours — never commit them).

| Secret | Used by | Where to get it |
|---|---|---|
| `EDGE_SHARED_SECRET` | notify-dispatch, push-dispatch, saved-search-alerts, meili-sync | any strong random string; also set as the DB `app.edge_shared_secret` (below) |
| `TELEGRAM_GATEWAY_TOKEN` | send-sms-hook (Telegram OTP sign-in) | https://gateway.telegram.org |
| `SEND_SMS_HOOK_SECRET` | send-sms-hook | generated by Supabase when you register the Send-SMS hook (§4) |
| `TELEGRAM_BOT_TOKEN` | notify-dispatch, telegram-webhook, telegram-channel-post | @BotFather |
| `TELEGRAM_WEBHOOK_SECRET` | telegram-webhook | any strong random string — also passed as `secret_token` when you register the webhook (below), so Telegram echoes it back on every update and forged calls are rejected |
| `WEBAPP_URL` | telegram-channel-post (job link in channel posts) | your production web domain, e.g. `https://yollla.uz` — *optional, defaults to that* |
| `FCM_SERVICE_ACCOUNT` | push-dispatch, notify-dispatch (push) | Firebase service-account JSON — *optional, only when push is provisioned* |
| `RESEND_API_KEY` | notify-dispatch, saved-search-alerts, lifecycle-email | https://resend.com → API Keys. **Without it no email is ever sent** (each send is logged as `skipped` in `email_deliveries`) |
| `EMAIL_FROM` | the same three | `Yolla <bildirishnoma@yollla.uz>` — the domain must be verified at the provider (SPF + DKIM + DMARC), see §4b |
| `EMAIL_REPLY_TO` | the same three | *optional*, e.g. `yordam@yollla.uz` |
| `EMAIL_API_BASE` | the same three | *optional* override for a Resend-compatible API (default `https://api.resend.com`) |
| `ANTHROPIC_API_KEY` | generate-job-content | *optional, only to enable real AI job-text generation* |

**DB-side secrets** (read by the `notify_dispatch` trigger and the
`send_sms_telegram` hook) go into `private.app_secrets` (0038) via the SQL
editor. Do **not** use `alter database … set` — Supabase's managed `postgres`
role is denied it (`42501: permission denied to set parameter`):

```sql
insert into private.app_secrets (name, value) values
  ('telegram_gateway_token', '<gateway.telegram.org token>'),
  ('notify_dispatch_url', 'https://<ref>.functions.supabase.co/notify-dispatch'),
  ('telegram_channel_post_url', 'https://<ref>.functions.supabase.co/telegram-channel-post'),
  ('lifecycle_email_url', 'https://<ref>.functions.supabase.co/lifecycle-email'),
  ('edge_shared_secret',  '<same as EDGE_SHARED_SECRET>')
on conflict (name) do update set value = excluded.value;
```

---

## 3. Edge Functions — deploy

```bash
supabase functions deploy notify-dispatch push-dispatch saved-search-alerts \
  send-sms-hook telegram-webhook telegram-channel-post lifecycle-email
```

| Function | Purpose | Extra step |
|---|---|---|
| `notify-dispatch` | mirrors each in-app notification to Telegram + push + **email** | needs §2 DB settings + `TELEGRAM_BOT_TOKEN`; email additionally needs `RESEND_API_KEY` + `EMAIL_FROM` |
| `saved-search-alerts` | runs the saved-search **and followed-company** matchers, then mails one job digest per person (see §5) | `EDGE_SHARED_SECRET` (+ email secrets for the digest) |
| `lifecycle-email` | the welcome email, fired by the `auth.users` signup/confirm triggers (0084) | needs the `lifecycle_email_url` DB secret + email secrets |
| `send-sms-hook` | delivers the auth OTP as a Telegram message | register it in §4 |
| `telegram-webhook` | links a signed-in user's Telegram for notifications | set the bot webhook to this URL **with** `secret_token`: `curl "https://api.telegram.org/bot<TELEGRAM_BOT_TOKEN>/setWebhook?url=https://<ref>.functions.supabase.co/telegram-webhook&secret_token=<TELEGRAM_WEBHOOK_SECRET>"` |
| `telegram-channel-post` | self-marketing: auto-posts a job to its category/region Telegram channel when it opens (admin CMS → *Telegram kanallar*) | needs §2 `telegram_channel_post_url` DB setting + `TELEGRAM_BOT_TOKEN`; add the bot as **admin** in every mapped channel |
| `push-dispatch` | FCM sender | *optional (push)* |
| `meili-sync` / `meili-reindex` / `search-jobs` | Meilisearch | *optional — search now runs on `job_feed` (Postgres) on both apps* |
| `generate-job-content` | AI job-text | *optional (`ANTHROPIC_API_KEY`)* |

---

## 4. Supabase Auth configuration

- **Phone** provider **enabled** — required for Telegram OTP sign-in.
- Dashboard → Authentication → Hooks → **Send SMS hook** → point at the
  `send-sms-hook` function; copy the generated secret into `SEND_SMS_HOOK_SECRET`.
- **Google** OAuth: client id/secret + redirect URLs for the web app and the
  mobile deep link (`io.jobzone.jobzone`).
- **Email/password** enabled, with **Confirm email ON**
  (`supabase/config.toml` → `[auth.email] enable_confirmations = true`). The web
  sign-up handles both branches, and the confirmation is what triggers the
  welcome mail (0084).
- **Email templates** — Authentication → Email Templates. Paste the branded,
  Uzbek-first files from `supabase/templates/` (`confirmation.html`,
  `magic_link.html`, `recovery.html`, `email_change.html`, `invite.html`), or
  apply them with `supabase config push`. Subjects are in
  `supabase/config.toml`. Without this, the one email *every* user is
  guaranteed to see is Supabase's English default.
- **Redirect URLs** must include the web origin (`/auth/callback`) and the
  mobile deep link, or a confirmation click lands signed-out.

---

## 4b. Email sending domain

Everything the platform mails — welcome, job alerts, application updates,
marketing broadcasts — goes through one provider (Resend by default) and one
`From` domain. Deliverability is entirely an ops step; the code is done.

1. **Add the domain** at the provider (`yollla.uz`) and publish the DNS records
   it gives you: **SPF**, **DKIM** and a **DMARC** record
   (`v=DMARC1; p=none; rua=mailto:dmarc@yollla.uz` to start, tighten to
   `p=quarantine` once the reports are clean). Gmail and Yahoo both require SPF
   + DKIM + DMARC alignment from bulk senders.
2. **Use a subdomain for bulk** if you ever send campaigns at volume
   (`mail.yollla.uz`), so an alert-fatigue complaint spike can't damage the
   reputation of the domain your transactional mail rides on.
3. Set `EMAIL_FROM` to a mailbox on that verified domain and `EMAIL_REPLY_TO`
   to one a human reads.
4. Point the provider's **Supabase Auth SMTP** settings (Project Settings →
   Auth → SMTP) at the same provider, so the confirmation/OTP mail comes from
   the same domain as everything else. Supabase's built-in sender is
   rate-limited and unbranded.
5. **One-click unsubscribe** is already wired: every alert/marketing mail sends
   `List-Unsubscribe` + `List-Unsubscribe-Post` pointing at
   `https://<web>/api/unsubscribe?token=…&scope=…`. Confirm the web app is
   deployed on the domain in `WEBAPP_URL` before the first campaign, or those
   headers point at nothing.

**Verify:** `select * from email_deliveries order by created_at desc limit 20;`
— every attempt is logged with `sent` / `failed` / `skipped` and the provider's
message id. A wall of `skipped: email not configured` means the secrets in §2
never reached the functions.

---

## 5. Scheduling (cron)

Two recurring jobs. Simplest is **pg_cron** calling the SQL directly (no HTTP):

```sql
-- Every 15 min: publish due scheduled drafts, then alert saved searches on the
-- jobs that just became open. Order matters — publish first so a freshly-live
-- vacancy falls inside the alert window.
select cron.schedule(
  'yolla-alerts', '*/15 * * * *',
  $$ select public.publish_due_jobs();
     select public.run_saved_search_alerts();
     select public.run_company_follow_alerts(); $$
);
```

> ⚠️ The SQL-only route creates the in-app/Telegram/push alerts but **not the
> email digest** — grouping a run's matches into one mail per person lives in
> the `saved-search-alerts` Edge Function. If you want the emails (you do:
> it's the feature seekers asked for), schedule the HTTP call instead:
>
> ```sql
> select cron.schedule(
>   'yolla-alerts', '*/15 * * * *',
>   $$ select public.publish_due_jobs();
>      select net.http_post(
>        url := 'https://<ref>.functions.supabase.co/saved-search-alerts',
>        headers := jsonb_build_object('Content-Type','application/json',
>                                      'x-edge-secret','<EDGE_SHARED_SECRET>')); $$
> );
> ```
>
> The function runs both matchers itself and then sends the digests.

Alternative: an external scheduler that `POST`s the `saved-search-alerts` Edge
Function with an `x-edge-secret: <EDGE_SHARED_SECRET>` header on the same cadence
(run `publish_due_jobs()` alongside it).

*(Meili users: also schedule `meili-reindex` nightly.)*

**Verify:** save a search (mobile Obunalar / web "Save search"), post a matching
vacancy, then POST the function once → a `job_match` notification appears
in-app, via Telegram/push, and one digest email lands in the inbox. The
notification's `data.emailed` flips to `true`, so a second run doesn't re-send
it.

---

## 6. Mobile / native

- **Yandex MapKit key** — committed (app-id-restricted). Restrict it to app id
  `io.jobzone.jobzone` in the Yandex cabinet. Mobile uses the official
  `yandex_maps_mapkit_lite` SDK; the web map is OSM and needs no key.
- **FCM (optional):** drop `android/app/google-services.json` and
  `ios/Runner/GoogleService-Info.plist` from the Firebase project, add the Gradle
  plugin lines and an APNs key — see `docs/phase-8-realtime-and-push.md`.
- Build and submit to the stores. **Do not change** the app id
  `io.jobzone.jobzone` / Dart package name — the auth deep links depend on it.

---

## 7. Web (Vercel)

- Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` in the
  Vercel project env (Production + Preview).
- Attach the production domain.

---

## 8. Post-deploy smoke tests

1. **Post → visibility:** an employer posts a vacancy → it appears in *both* the
   mobile app and the web app under its category (both read `job_feed`).
2. **Telegram OTP:** enter a phone number on sign-in → receive the code as a
   Telegram message → verify → signed in.
3. **Saved-search alert:** save a search → post a matching vacancy → the cron (or
   a manual `run_saved_search_alerts()`) delivers a `job_match` notification.
   With the email secrets set, the same run sends **one digest email** listing
   every match — check `email_deliveries` for `kind = 'job_alert', status =
   'sent'`.
4. **Apply:** a seeker applies → the employer sees the applicant; a status change
   notifies the seeker.
5. **Wallet:** an employer top-up records a `pending` order in the ledger.
6. **Signup → welcome:** register a new account with a real address → the
   branded confirmation mail arrives → after confirming, exactly one welcome
   email follows (`email_deliveries.kind = 'welcome'`, `dedupe_key =
   welcome:<uid>`), and re-confirming never produces a second one.
7. **Unsubscribe:** click *Obunani bekor qilish* in a job-alert email → the
   landing page confirms → `notification_settings.email_job_match` is `false`
   for that profile, the in-app notifications keep coming, and the account's
   *Sozlamalar* page shows the switch off.
8. **Telegram channel auto-post:** map a category+region to a test channel in
   *admin → Telegram kanallar*, post a matching vacancy → it appears in the
   channel within seconds (needs `telegram_channel_post_url` set and the bot
   added as channel admin).
