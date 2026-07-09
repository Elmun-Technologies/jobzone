# Yolla (repo: jobzone) — project guide

**Yolla** is a trusted, mobile-first **job marketplace for Uzbekistan**, aimed at
blue-collar / mass hiring (the apna.co / enbek.kz gap that hh.uz and OLX don't
fill locally). One shared **Supabase** backend serves two deliberately different
clients:

- **Mobile app** (`lib/`) — Flutter, iOS + Android. The full seeker + employer
  product ("Yolla Business") behind sign-in.
- **Web app** (`webapp/`) — Next.js 16. A public, SEO-friendly marketplace where
  a guest can do everything and only signs in at the last step.

Brand: **Yolla** — volt `#C7FB00` on ink `#0A0A0A`, Archivo type, the "yo"
speech-bubble mark (`assets/icon/`). UI copy is Uzbek-first (uz default, ru, en).

> ⚠️ Identity constants that must NEVER change: Android/iOS app id
> **`io.jobzone.jobzone`** and the Dart package name **`jobzone`** — auth deep
> links and store identity depend on them. "Yolla" is the display brand only.

---

## Repo map

```
lib/            Flutter app (feature-first: data / domain / presentation per feature)
  app/          MaterialApp, go_router (two StatefulShellRoutes + guards), routes
  core/         env/config, supabase client providers, local cache, utils
  design_system/ theme tokens (JzColors, spacing/radius) + Jz* widgets
  localization/ l10n/*.arb (en/ru/uz) → generated AppLocalizations
  shared/       DB-mirrored enums (wire/fromWire), app flags, shared widgets
  features/     auth · onboarding · preferences · permissions · home · jobs ·
                search · applications · profile · companies · reviews · chat ·
                notifications · calls · account · employer · monetization · splash
webapp/         Next.js 16 web client (see webapp/CLAUDE.md → AGENTS.md note)
  src/app/[locale]/   App Router pages (uz default / ru / en via next-intl)
  src/lib/data/       server-only Supabase readers (job_feed etc.)
  src/lib/actions/    server actions (jobs, companies, resumes, saved searches…)
  src/proxy.ts        auth gate for /account + /employer (with guest carve-outs)
supabase/
  migrations/   0001…0036 — entire schema, RLS, triggers, views, buckets
  functions/    13 edge functions (see Backend below)
  seed.sql · seed_dev.sql
android/ ios/ web/   native shells (icons/splash generated from assets/icon/)
docs/           go-live-checklist.md · audit-findings.md · phase-8 (calls/push) · …
test/           Flutter tests (incl. arb_parity, router guards, repos, widgets)
.github/workflows/  ci.yml (Flutter) · webapp-ci.yml (web) · web-deploy.yml
```

---

## Product invariants (user-mandated — do not violate)

1. **One database, two fundamentally different UIs.** Never mirror a mobile
   screen onto web or vice versa. Each platform gets its native shape (e.g.
   mobile saved-searches = FAB + bottom sheet; web = toolbar button + account
   page).
2. **Mobile is auth-first** (sign in → role → onboarding → app).
   **Web is auth-last**: a guest browses jobs, fills the entire résumé wizard,
   the apply form, even the post-vacancy form — auth is requested only at the
   final action (save/apply/publish), and nothing typed is ever lost
   (sessionStorage stash → sign-in?next=… → restore + form remount).
3. **Posting must be automatically visible everywhere.** An employer posts a
   vacancy → it appears in BOTH apps under its category immediately, via the
   shared `job_feed` view. No manual publish/reindex step may ever be required.
4. **Everything runs offline.** With no Supabase env, both clients boot fully on
   mock data (`Env.hasSupabase` / `hasSupabase()` gate every live call; errors
   degrade gracefully). Never break the offline path — it's the demo and the
   test substrate.
5. **Clients can never grant themselves privileges** (see Security).

---

## Mobile app (`lib/`)

- **Stack:** Flutter (Dart ^3.12), Material 3, Riverpod 3 (manual notifiers, no
  codegen), go_router with **two** `StatefulShellRoute`s — seeker shell
  (`/home /explore /bookmarks /chat /profile`) and employer shell
  (`/employer/*`) — selected by the pure `resolveRedirect` guard
  (`lib/app/router/guards.dart`, truth-table tested).
- **Roles:** one account = one role (`job_seeker` | `employer`), chosen once at
  registration (`ChooseRolePage`); the router guard enforces the choice for
  every auth path (email OTP and Google). No role switching.
- **Repositories:** `_live ? supabase : mock` in every feature repo. Mock data
  in `lib/features/jobs/data/mock_jobs.dart` (+ per-feature seeds) demos the
  whole product.
- **Jobs/search data source:** the **`job_feed` Postgres view** for home,
  categories, and search (`SearchRepository._applyFilters` builds one filter
  chain shared by `search()` and the HEAD-only `count()` that powers the live
  "N vakansiya" button). Meilisearch (`SearchQuery`, `search-jobs` fn) is
  legacy-optional — kept for tests, not the live path.
- **Employer suite:** dashboard, post/edit vacancy (blue-collar fields:
  schedule 6/1 etc., formalization, night shift, women/disability-friendly,
  driver licenses `kDriverLicenseCategories` in `shared/enums/enums.dart`,
  languages, pay basis, screening questions editor, markdown description, OSM
  location picker, scheduled publish), applicants pipeline with status history,
  distance sort + applicants map (official Yandex SDK on device, OSM on web),
  company/people/gallery admin, monetization (promote sheet, wallet).
- **l10n:** `lib/localization/l10n/app_{en,ru,uz}.arb` → `flutter gen-l10n`.
  `test/localization/arb_parity_test.dart` enforces identical keys across the
  three files, **ignoring `@`-metadata** — so placeholder metadata lives in the
  en template only.
- **Notifications:** in-app list reads `notifications`; push scaffolded
  (`FcmPushService` behind a provider seam, no-op without Firebase files);
  Telegram link via `telegram_links` + `/start` handshake.

## Web app (`webapp/`)

- **Stack:** Next.js **16** (App Router, RSC; `src/proxy.ts` is the middleware),
  TypeScript, Tailwind v4, next-intl v4, `@supabase/ssr`, vitest.
  **Heed `webapp/AGENTS.md`:** this Next version differs from training data —
  read `node_modules/next/dist/docs/` before using unfamiliar APIs.
- **Routing/gating:** `proxy.ts` gates `/account` and `/employer` but carves out
  guest paths (`/employer/jobs/new`). Server components re-check with
  `getCurrentUser()` / `requireEmployer()` (DAL-style).
- **⚠️ Static-prerender trap:** `getCurrentUser()` wraps `cookies()` in
  try/catch, which **swallows Next's dynamic-rendering signal** — any
  auth-dependent page must export `const dynamic = "force-dynamic"` or it gets
  baked as one shared logged-out HTML. Applied to all `/employer/*` pages,
  `resumes/new`. Check the build's route table (`ƒ` vs `●`) for new gated pages.
- **Data layer** (`src/lib/data/*`): server-only readers from `job_feed`;
  **every seeker listing/count read filters `.eq("status","open")`** (RLS shows
  owners their own drafts, so relying on RLS alone diverges from mobile).
- **Auth:** email/password + Google OAuth + **Telegram OTP** (Supabase phone-OTP
  whose delivery is redirected to Telegram Gateway by the `send-sms-hook` edge
  function; client = `phone-otp-form.tsx` using `signInWithOtp`/`verifyOtp`).
  Telegram OTP works only after the go-live config (hook + secrets) — see
  `docs/go-live-checklist.md` §2–4.
- **Employer web:** onboarding (creating a company promotes `profiles.role` to
  employer), post vacancy (guest-first), my jobs, applicants, company edit,
  wallet (Hamyon) with top-up form (records pending transactions only).

## Backend (`supabase/`)

- **Schema domains** (36 migrations): profiles/CV (experiences, educations,
  skills, resumes…), companies (+people/gallery/reviews), job_categories
  (seeded blue-collar set incl. Foreign-jobs), jobs (rich blue-collar fields +
  screening_questions jsonb + boost + expiry + publish_at), applications
  (+status history trigger), bookmarks, chat (conversations/messages,
  Realtime), notifications (+settings), devices, monetization
  (promotion_products/orders, wallet_transactions + wallet_balances view),
  verification (companies + workers), worker_reviews + reliability,
  interview_confirmations, telegram_links, saved_searches (+ alert watermark).
- **`job_feed` view — the one feed contract** (0034/0036 era): jobs ⋈ companies
  ⋈ categories, `boost_active` computed, **filters expiry only**; RLS
  (`status='open'` readable by all, owners see their own everything) plus the
  clients' explicit `status='open'` filters produce the seeker view. Recreating
  it requires `drop view` first (column-order rule) — see any of 0011/0021/…
- **Security guards (pattern: BEFORE-trigger pins protected columns unless a
  txn-local flag set by a `security definer` RPC):** boosts (`apply_promotion`),
  company/worker verification (`is_admin()` RPCs), wallet (clients may insert
  only *pending* top-ups; balances = completed rows only), notifications
  (inserted only by definer functions/service role). Application status changes
  go through `application_status_history` inserts — never write
  `current_status` directly.
- **Notification pipeline:** INSERT into `notifications` → pg_net AFTER-INSERT
  trigger (0026, reads `app.notify_dispatch_url` + `app.edge_shared_secret`) →
  `notify-dispatch` fn → Telegram (if linked) + FCM (if configured), honoring
  `notification_settings`. So any feature notifies all channels by inserting
  one row.
- **Saved-search alerts (0036):** `run_saved_search_alerts()` matches jobs
  posted since each search's `last_alerted_at` (keywords ILIKE
  title/company/category + city), inserts `job_match` notifications
  (data: `{job_id, saved_search_id}`), advances the watermark under an advisory
  lock. `publish_due_jobs()` flips due scheduled drafts to open **and stamps
  `posted_at = now()`**. Both must run on a cron (go-live §5) — order: publish
  first, then alerts.
- **Edge functions** (`supabase/functions/`, shared helpers in `_shared/`):
  `notify-dispatch`, `saved-search-alerts`, `send-sms-hook` (Telegram OTP
  delivery, Standard-Webhooks-verified), `telegram-webhook` (/start link),
  `push-dispatch` (FCM), `payment-webhook` (Click/Payme stub),
  `generate-job-content` (AI seam — templates now, Claude when
  `ANTHROPIC_API_KEY` set), `agora-token` (calls), `send-notification`, and the
  legacy Meili trio (`meili-sync`/`meili-reindex`/`search-jobs`). All
  server-to-server ones are gated by `EDGE_SHARED_SECRET` (fail closed).

---

## Verify & CI (run these before every commit)

**Flutter** (`ci.yml` — runs on push/PR):
```bash
flutter pub get && flutter gen-l10n
flutter analyze
flutter test
dart format --set-exit-if-changed $(git ls-files '*.dart')
```

**Web** (`webapp-ci.yml`, path-scoped to `webapp/**`):
```bash
cd webapp && pnpm typecheck && pnpm lint && pnpm test && pnpm build
```

- Migrations are **not** applied in CI — they reach the DB via the user's
  `supabase db push` (Supabase Preview check is informational). SQL therefore
  ships on careful review; say so in the PR.
- `web-deploy.yml` publishes the **Flutter web build** to GitHub Pages;
  the Next.js webapp deploys via **Vercel** (root directory `webapp/`,
  `NEXT_PUBLIC_SUPABASE_URL` / `NEXT_PUBLIC_SUPABASE_ANON_KEY` envs).

## Conventions for Claude sessions

- **Branch/PR loop:** work on the designated session branch; one focused PR at
  a time (the user prefers clean, single-purpose diffs). Push → **draft PR** →
  the user reviews/merges fast. After a merge, restart the branch from main
  (`git fetch origin main && git checkout -B <branch> origin/main`). While a PR
  is open, hold further work as `git format-patch` output (scratchpad) instead
  of stacking commits.
- **Remote env quirks:** no Flutter SDK (CI is the analyze/test gate — but
  fetch the standalone **Dart SDK** into the scratchpad to run `dart format`
  locally; a format failure is the most common CI break). `deno.land` egress is
  proxy-denied (typecheck edge fns against a Deno-global stub if needed).
  Package APIs can be verified against `/root/.pub-cache/hosted/pub.dev/…`.
- **Git hygiene:** committer `Claude <noreply@anthropic.com>`; write commit
  messages to a file and use `git commit -F` (shell-quoting); never mention the
  model id in commits/PRs; commit only when the tree is clean of unrelated WIP.
- **i18n discipline:** every user-facing string in all three locales (mobile
  ARB parity test / webapp message-parity test enforce it); uz is the product's
  first language — write it natively, not as a translation afterthought.
- **Money:** UZS is the default currency (USD optional); salary required
  form-side; amounts grouped "2 500 000 so'm" (`formatUzs` / `groupNumber`).

## Status & roadmap

**Shipped (code-complete):** full seeker + employer mobile app, public web
marketplace with auth-last flows, Telegram OTP + Google + email auth,
screening questions, wallet, promotions/TOP, verification & reliability
layers, chat, saved searches **with alerts**, category pipeline, filters with
live counts, real AI on `generate-job-content` and the résumé "About me"
assist, web in-app notifications, mobile category-label localization
(uz/ru/en), the two-way résumé match (employer sees candidates for a new
posting via `recommended_candidates`, seeker sees jobs matched to their résumé
via `recommended_jobs` — one shared scoring algorithm per side, both clients
call the same RPC), one-tap apply from any job card (web + mobile), a seeker's
"archive" control over their browse feed, a map-first mobile Home, and the
go-live runbook (`docs/go-live-checklist.md`).

**Go-live is ops, not code** (user's side): `supabase db push` (→0052),
secrets (`EDGE_SHARED_SECRET`, `TELEGRAM_GATEWAY_TOKEN`, `SEND_SMS_HOOK_SECRET`,
`TELEGRAM_BOT_TOKEN`…), deploy edge fns, enable Phone auth + register the
Send-SMS hook, schedule the cron (§5), Vercel envs, store submission.

**Queued next (genuinely needs third-party ops, not just code):** real
payments via `payment-webhook` (Click/Payme merchant accounts), FCM native
config (a real Firebase project + `google-services.json`/`GoogleService-
Info.plist`), Agora calls (a real Agora project + app credentials).

**Docs to read when relevant:** `docs/go-live-checklist.md` (ops),
`docs/phase-8-realtime-and-push.md` (calls/FCM wiring),
`docs/audit-findings.md` (known-issue backlog), `webapp/AGENTS.md`
(Next.js 16 warning), `README.md` (historic — some sections predate the Yolla
rebrand and the job_feed search unification).
