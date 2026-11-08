# Yolla (repo: `jobzone`) — Developer Guide

> A complete onboarding manual for **any** developer joining the project.
> If you only read one file first, read this one. For the terse, agent-oriented
> project map, see [`CLAUDE.md`](CLAUDE.md). For the Next.js quirks, see
> [`webapp/AGENTS.md`](webapp/AGENTS.md).

---

## 1. What is Yolla?

**Yolla** is a trusted, mobile-first **job marketplace for Uzbekistan**, aimed at
**blue-collar / mass hiring** — the local gap that hh.uz and OLX don't fill (the
apna.co / enbek.kz model). The product name is **Yolla**; the repo, package and
app IDs are still `jobzone` for historical reasons (see the identity rule below).

One shared **Supabase** backend serves **three** deliberately different clients:

| Client | Path | Stack | Audience |
|---|---|---|---|
| **Mobile app** | `lib/` | Flutter (iOS + Android) | Seekers + employers, sign-in first |
| **Web app** | `webapp/` | Next.js 16 | Public marketplace, sign-in last |
| **Admin panel** | `webapp/src/app/[locale]/admin/` | Next.js 16 | Platform operators only |

> ### ⚠️ Identity constants that must NEVER change
> Android/iOS app id **`io.jobzone.jobzone`** and the Dart package name
> **`jobzone`**. Auth deep links and store identity depend on them.
> **"Yolla" is the display brand only.**

**Brand:** volt `#C7FB00` on ink `#0A0A0A`, Archivo type, the "yo" speech-bubble
mark (`assets/icon/`). UI copy is **Uzbek-first** (uz default, then ru, en).

---

## 2. Product invariants (never violate these)

These are user-mandated. Breaking one is a bug even if tests pass.

1. **One database, three different UIs.** Never mirror a mobile screen onto web
   or vice-versa. Each platform gets its native shape (e.g. mobile
   saved-searches = FAB + bottom sheet; web = toolbar button + account page).
2. **Mobile is auth-first** (sign in → role → onboarding → app).
   **Web is auth-last:** a guest browses jobs, fills the entire résumé wizard,
   the apply form, even the post-vacancy form — auth is requested only at the
   final action (save/apply/publish), and **nothing typed is ever lost**
   (sessionStorage stash → `sign-in?next=…` → restore + form remount).
3. **Posting is automatically visible everywhere.** An employer posts a vacancy
   → it appears in BOTH apps under its category immediately, via the shared
   **`job_feed`** view. No manual publish/reindex step, ever.
4. **The product is online-only — no demo data may ever render.** All content
   comes from the live backend. Web: every `!hasSupabase()` branch returns
   empty/null. Mobile: `bootstrap()` fails fast into a "misconfigured build"
   screen without Supabase env; the repos' `_live ? supabase : mock` seams
   are the **unit-test substrate only** and unreachable in a booted app.
5. **Clients can never grant themselves privileges.** All privilege escalation
   is blocked at the database layer (see §7 Security).

---

## 3. Getting started

### 3.1 Prerequisites

Start with Git and a fresh clone (see [README](README.md#start-here)). Run commands
from the repository root unless a block explicitly changes directories. The web
and mobile clients can be installed independently; neither test suite needs
backend credentials. Use a shell such as Bash for the commands below.

| Tool | Version | Installation / purpose |
|---|---|---|
| Git | current | [Install Git](https://git-scm.com/downloads) |
| Flutter SDK | `3.44.2` stable | [Install Flutter](https://docs.flutter.dev/install), selecting this version from the [SDK archive](https://docs.flutter.dev/install/archive); matches CI |
| Dart | `3.12` bundled with Flutter | Do not install a separate Dart SDK for mobile checks |
| Node.js | `22.13+` in the `22.x` line | [Install Node](https://nodejs.org/en/download); CI uses Node 22 |
| pnpm | `10.x` | After Node: `npm install --global pnpm@10` ([alternatives](https://pnpm.io/installation)) |
| Supabase CLI | `3.0.0` (tested) | Optional, for backend work (§3.4) |
| Docker Engine / Desktop | current, daemon running | Optional, for local Supabase only |
| Deno | current | Optional, for edge-function development |

Check `flutter --version`, `node --version`, and `pnpm --version` for your chosen
client. Older Node 20 releases and pnpm 9 are not the documented web toolchain;
the locked test dependencies need newer Node versions than Next alone does.
Flutter installation also needs the OS prerequisites listed in its installer.

### 3.2 Run the mobile app

For a credential-free check, no emulator or native SDK is needed:

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
```

For an actual app session, first obtain a development Supabase backend (§3.4):

```bash
cp env/dev.example.json env/dev.json
# Edit env/dev.json: fill SUPABASE_URL and SUPABASE_ANON_KEY.
flutter doctor -v
flutter devices
flutter run --dart-define-from-file=env/dev.json
```

For Android, install Android Studio/SDK, accept licenses with
`flutter doctor --android-licenses`, and start an emulator or connect a device.
For iOS, use macOS with Xcode and CocoaPods; follow `flutter doctor` for missing
components. Firebase push, Yandex maps, signing, and store release configuration
are separate integration steps; see `docs/phase-8-realtime-and-push.md` and
`docs/android-signing.md`.

`Env` (`lib/core/config/env.dart`) reads compile-time defines, not a dotenv file.
Changing `env/dev.json` requires rerunning the app with the flag above. There is
**no baked-in backend or offline demo in any build mode**: missing URL/key shows
a misconfigured-build screen. Unit tests exercise mock repository seams directly.
`SEARCH_PROXY_URL` can stay empty for the normal Postgres-backed job search.

### 3.3 Run the web app

From the repository root:

```bash
cd webapp
pnpm install --frozen-lockfile
pnpm typecheck
pnpm lint
pnpm test
pnpm build
pnpm dev                    # http://localhost:3000 → /uz
```

Tests and the production build require no secrets. Without Supabase variables,
the running site renders empty states and auth is disabled, not mock data.
`pnpm start` serves an existing `pnpm build`; it does not compile the app.

For a backend, stop the server, then from `webapp/`:

```bash
cp .env.example .env.local
# Edit .env.local: fill NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY.
pnpm dev
```

Do not commit real environment files. Admin cross-owner reads also need a
server-only `SUPABASE_SERVICE_ROLE_KEY` (see §6.3); it is unnecessary for public
pages or tests. Never prefix this key with `NEXT_PUBLIC_`. Maps, analytics,
payments, email, and other third-party variables are optional for the basic
build/test path; the template describes them.

### 3.4 Backend (optional)

Backend setup is **not** required for the checks above. For live client work,
ask a maintainer for an approved development project's URL and public anon key,
or use a local stack. Never reset a shared database or use production secrets
for onboarding.

See the [Supabase CLI installation guide](https://supabase.com/docs/guides/local-development/cli/getting-started).
The tracked config targets CLI 3.0.0 (`local_smtp`, project-root template paths);
check `supabase --version` before continuing. Do not run `supabase init` to
overwrite this repository's configuration. Docker must be running for a local stack; `supabase db reset` alone does not
provision a hosted project or start Docker. Run local commands at repository
root.

```bash
docker info
supabase start -x vector    # omit the optional Vector logging collector
supabase db reset          # DESTRUCTIVE: only the local development database
supabase status            # local API URL, public anon key, Studio, mail UI
```

Copy only the public URL/anon key into the client files in §3.2/§3.3. Do not
copy service-role/secret keys into client config. Local data is disposable;
`supabase stop` stops the stack when finished. See the [setup audit](docs/setup-audit.md)
for the tested CLI version and any local-stack verification limits.

**Hosted deployment is maintainer-only, not part of the quick start.** With
permission and a disposable/development project, authenticate and link before
pushing; replace placeholders rather than pasting them literally:

```bash
supabase login
supabase link --project-ref <development-project-ref>
supabase db push
supabase functions deploy <function-name>
```

Do not run a bulk legacy Meilisearch deployment to enable normal job search.
For function-specific secrets, auth providers/hooks, and cron, follow
`docs/go-live-checklist.md`. Migrations are not applied in CI; SQL changes need
explicit review. `bash scripts/check-migrations.sh` checks filenames/versions,
not SQL execution.

---

## 4. Repository map

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

webapp/         Next.js 16 web client + admin panel
  src/app/[locale]/   App Router pages (uz default / ru / en via next-intl)
    admin/            platform admin panel (see §6)
  src/lib/data/       server-only Supabase readers (job_feed etc.)
  src/lib/actions/    server actions (jobs, companies, resumes, saved searches…)
    actions/admin/    admin mutations (moderation, finance, categories, broadcast…)
  src/lib/admin/      admin readers + env/nav/types
  src/proxy.ts        auth gate for /account + /employer + /admin (guest carve-outs)

supabase/
  migrations/   versioned SQL — entire schema, RLS, triggers, views, buckets
  functions/    edge functions (see §7)
  seed.sql

android/ ios/ web/   native shells (icons/splash generated from assets/icon/)
docs/           go-live-checklist.md · audit-findings.md · phase-8 (calls/push) · …
test/           Flutter tests (arb_parity, router guards, repos, widgets)
webapp/tests/   vitest (admin-role, messages-parity, pricing, seo, …)
.github/workflows/  ci.yml (Flutter) · webapp-ci.yml (web) ·
                    web-deploy.yml (Pages) · android-apk.yml (test APK)
```

---

## 5. Mobile app (`lib/`) — architecture

- **Stack:** Flutter (Material 3), **Riverpod 3** (manual notifiers, no codegen),
  **go_router**. Navigation is **two** `StatefulShellRoute`s — the seeker shell
  (`/home /explore /bookmarks /chat /profile`) and the employer shell
  (`/employer/*`) — selected by the **pure `resolveRedirect` guard**
  (`lib/app/router/guards.dart`, truth-table tested).
- **Roles:** one account = one role (`job_seeker` | `employer`), chosen once at
  registration (`ChooseRolePage`). The router guard enforces it for every auth
  path (email OTP + Google). **No role switching.**
- **Repositories:** every feature repo is `_live ? supabase : mock`. The mock
  branch (`lib/features/jobs/data/mock_jobs.dart` + per-feature seeds) is the
  unit-test substrate only — `bootstrap()` refuses to boot without Supabase env.
- **Jobs/search data source:** the **`job_feed` Postgres view** powers home,
  categories and search. `SearchRepository._applyFilters` builds one filter
  chain shared by `search()` and the HEAD-only `count()` behind the live
  "N vakansiya" button. Meilisearch (`search-jobs` fn) is **legacy-optional** —
  kept for tests, not the live path.
- **Maps:** the mobile map uses the **official `yandex_maps_mapkit_lite` SDK** on
  device (the community `yandex_mapkit` plugin is abandoned); web uses OSM/Leaflet.
  Markers show the **job title**, follow the app's light/dark theme, and open a
  preview sheet on tap.
- **Employer suite:** dashboard, post/edit vacancy (blue-collar fields: schedule
  6/1, formalization, night shift, women/disability-friendly, driver licenses
  `kDriverLicenseCategories`, languages, pay basis, screening-questions editor,
  markdown description, OSM location picker, scheduled publish), applicants
  pipeline with status history, distance sort + applicants map, company /
  people / gallery admin, monetization (promote sheet, wallet).
- **Notifications:** in-app list reads `notifications`; **push is wired** via
  Firebase (`firebase_core` + `firebase_messaging`, `FcmPushService`) — no-op
  without the Firebase config files. Telegram link via `telegram_links` +
  `/start` handshake.

---

## 6. Web app (`webapp/`) — architecture

- **Stack:** Next.js **16** (App Router, RSC), TypeScript, **Tailwind v4**,
  **next-intl v4**, `@supabase/ssr`, **vitest**. `src/proxy.ts` is the middleware.
- **⚠️ Read `webapp/AGENTS.md` first.** This Next version differs from most
  training data — read `node_modules/next/dist/docs/` before using an unfamiliar
  API.

### 6.1 Routing & gating

`proxy.ts` gates `/account`, `/employer` and `/admin`, but **carves out guest
paths** (e.g. `/employer/jobs/new`). Server components re-check with
`getCurrentUser()` / `requireEmployer()` (DAL-style).

> **Static-prerender trap:** `getCurrentUser()` wraps `cookies()` in try/catch,
> which **swallows Next's dynamic-rendering signal**. Any auth-dependent page
> must export `const dynamic = "force-dynamic"` or it gets baked as one shared
> logged-out HTML. Check the build's route table (`ƒ` vs `●`) for new gated pages.

### 6.2 Data layer

`src/lib/data/*` holds **server-only** readers from `job_feed`. **Every seeker
listing/count read filters `.eq("status","open")`** — RLS shows owners their own
drafts, so relying on RLS alone diverges from mobile.

### 6.3 Admin panel (`/admin`)

The admin panel is **web-only** — there is no mobile admin. It covers:
**dashboard** (aggregate stats RPC), **jobs** & **companies** & **reviews**
moderation, **users**, **orders**, **finance** (wallet top-ups, promotion orders,
pricing), **categories** CMS, **broadcast** (one notification to a whole
audience), **audit** log, and **settings** (platform config + site-wide banner).

- **Gate:** the existing `is_admin()` DB function — `JWT app_metadata.role =
  'admin'` (from `0016_verification.sql`). Admins are granted/revoked from the
  panel itself (`0054_admin_grants.sql`).
- **Audit:** every admin action writes to `admin_audit_log` via the
  `admin_audit()` security-definer helper. Clients have **no** insert policy;
  only admins can read it.
- **Server key:** cross-owner list screens need `SUPABASE_SERVICE_ROLE_KEY`
  (server-only). Without it the panel still runs in **degraded mode** — the
  dashboard RPC and mutations fall back to the anon client
  (`webapp/src/lib/admin/env.ts`, `hasAdminSupabase()`).
- **Code layout:** readers in `src/lib/admin/data/*`, mutations in
  `src/lib/actions/admin/*`, UI in `src/components/admin/*`.

### 6.4 Auth (web)

Email/password + Google OAuth + **Telegram OTP**. Telegram OTP is a Supabase
phone-OTP whose SMS delivery is redirected to the **Telegram Gateway** by the
`send-sms-hook` edge function; the client is `phone-otp-form.tsx`
(`signInWithOtp` / `verifyOtp`). It works **only after go-live config** (hook +
secrets) — see `docs/go-live-checklist.md` §2–4.

---

## 7. Backend (`supabase/`)

- **Schema (`supabase/migrations/` is the source of truth):** profiles/CV, companies
  (+people/gallery/reviews), job_categories (blue-collar set incl. Foreign-jobs),
  jobs (rich fields + `screening_questions` jsonb + boost + expiry + `publish_at`),
  applications (+status-history trigger), bookmarks, chat, notifications,
  devices, monetization (promotion products/orders, wallet), verification,
  worker reviews + reliability, interview confirmations, telegram_links,
  saved_searches (+ alert watermark), recommendations, dismissed jobs, and the
  **admin foundation** (`0037`–`0057`: audit log, moderation, grants, finance,
  broadcast, category CMS, settings).
- **`job_feed` view — the one feed contract:** jobs ⋈ companies ⋈ categories,
  `boost_active` computed, **filters expiry only**. RLS (`status='open'` readable
  by all; owners see their own everything) plus the clients' explicit
  `status='open'` filters produce the seeker view. **Recreating it requires
  `drop view` first** (column-order rule) — see any of `0011`/`0021`/`0034`.

### 7.1 Security guards (the core pattern)

**A BEFORE-trigger pins protected columns unless a txn-local flag is set by a
`security definer` RPC.** This is how clients can never escalate privileges:

- **Boosts** → `apply_promotion` RPC.
- **Company/worker verification** → `is_admin()` RPCs.
- **Wallet** → clients may insert **only `pending` top-ups**; balances count
  completed rows only.
- **Notifications** → inserted only by definer functions / service role.
- **Application status** → always via `application_status_history` inserts;
  **never write `current_status` directly.**
- **Admin writes** → only inside admin definer RPCs, each calling `admin_audit()`.

### 7.2 Notification pipeline

INSERT into `notifications` → pg_net AFTER-INSERT trigger (`0026`, reads
`app.notify_dispatch_url` + `app.edge_shared_secret`) → `notify-dispatch` fn →
Telegram (if linked) + FCM (if configured), honoring `notification_settings`.
**Any feature notifies all channels by inserting one row.**

### 7.3 Saved-search alerts & scheduled publish (`0036`)

- `run_saved_search_alerts()` matches jobs posted since each search's
  `last_alerted_at` (keyword ILIKE on title/company/category + city), inserts
  `job_match` notifications, advances the watermark under an advisory lock.
- `publish_due_jobs()` flips due scheduled drafts to `open` **and stamps
  `posted_at = now()`**.
- Both run on cron (go-live §5) — **order: publish first, then alerts.**

### 7.4 Edge functions (`supabase/functions/`, shared in `_shared/`)

`notify-dispatch`, `saved-search-alerts`, `send-sms-hook` (Telegram OTP delivery,
Standard-Webhooks-verified), `telegram-webhook` (`/start` link), `push-dispatch`
(FCM), `payment-webhook` (Click/Payme stub), `generate-job-content` (AI — templates
now, Claude when `ANTHROPIC_API_KEY` set), `agora-token` (calls), `send-notification`,
and the legacy Meili trio (`meili-sync` / `meili-reindex` / `search-jobs`). Every
server-to-server function is gated by `EDGE_SHARED_SECRET` (fail closed).

---

## 8. Verify & CI — run before every commit

### Flutter (`.github/workflows/ci.yml`, runs on push/PR)

```bash
flutter pub get && flutter gen-l10n
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed $(git ls-files '*.dart')
```

> **The #1 CI break is `dart format`.** If you can't run Flutter locally, at
> least run `dart format` (the standalone Dart SDK is enough).

### Web (`.github/workflows/webapp-ci.yml`, path-scoped to `webapp/**`)

```bash
cd webapp && pnpm typecheck && pnpm lint && pnpm test && pnpm build
```

### Other workflows

- **`web-deploy.yml`** publishes the **Flutter web build** to GitHub Pages.
- **`android-apk.yml`** builds an installable **test APK** and attaches it to a
  rolling `apk-latest` pre-release (debug-signed, talks to the live demo
  backend). Runs on demand and on pushes to `main`. *(Note: its `push` trigger
  is pinned to specific branches — update the branch list if you want automatic
  APKs from a new dev branch.)*
- The Next.js webapp deploys to **Vercel** (root `webapp/`, with
  `NEXT_PUBLIC_SUPABASE_URL` / `NEXT_PUBLIC_SUPABASE_ANON_KEY`).

---

## 9. Conventions

- **Branch / PR loop:** one **focused, single-purpose PR** at a time (clean
  diffs preferred). Push → **draft PR** → maintainer reviews/merges fast. After a
  merge, **restart your branch from main**
  (`git fetch origin main && git checkout -B <branch> origin/main`) — never stack
  new commits on already-merged history.
- **Commits:** committer `Claude <noreply@anthropic.com>` for agent work; clear,
  descriptive messages; commit only when the tree is clean of unrelated WIP.
- **i18n discipline:** every user-facing string in **all three locales**.
  - Mobile: `lib/localization/l10n/app_{en,ru,uz}.arb` → `flutter gen-l10n`.
    `test/localization/arb_parity_test.dart` enforces identical keys (ignoring
    `@`-metadata, so placeholder metadata lives in the **en** template only).
  - Web: messages under `webapp/messages/`; a **message-parity test** enforces it.
  - **uz is the product's first language — write it natively**, not as an
    afterthought translation.
- **Money:** UZS is the default (USD optional); salary is required form-side;
  amounts grouped `2 500 000 so'm` (`formatUzs` / `groupNumber`).
- **Design system:** use `JzColors` tokens + `Jz*` widgets (mobile) / Tailwind
  tokens (web) — don't hardcode brand colors.

---

## 10. Troubleshooting & environment notes

- **No Supabase env is fine** — both apps run on mock data. If a live feature
  looks dead, check `Env.hasSupabase` / `hasSupabase()` first.
- **`dart format` failures** are the most common CI red. Fetch the standalone
  Dart SDK if you can't install full Flutter.
- **`deno.land` egress may be proxy-blocked** in some CI/remote environments —
  typecheck edge functions against a Deno-global stub if needed.
- **`win32` pin (`^6.3.0`)** in `pubspec.yaml` is load-bearing: `file_picker`
  and `package_info_plus` compile their Windows impl even for Android builds, so
  they must agree on the win32 major or the release APK won't compile. Don't
  bump it casually — read the comment in `pubspec.yaml`.
- **Next.js 16 surprises** → the docs are shipped in `node_modules/next/dist/docs/`.

---

## 11. Status & roadmap

**Shipped (code-complete):** full seeker + employer mobile app; public web
marketplace with auth-last flows; **platform admin panel** (moderation, finance,
categories, broadcast, audit, settings); Telegram OTP + Google + email auth;
screening questions; wallet; promotions/TOP; verification & reliability; chat;
saved searches **with alerts**; category pipeline; filters with live counts;
real AI on `generate-job-content` and the résumé "About me" assist; two-way
résumé match (`recommended_candidates` / `recommended_jobs`, one shared scoring
algorithm per side, both clients call the same RPC); one-tap apply from any card;
seeker "archive"/dismiss control; map-first mobile Home with the **official
Yandex SDK**; **Firebase push wired**; the go-live runbook.

**Go-live is ops, not code** (maintainer's side): `supabase db push` (all pending migrations),
secrets (`EDGE_SHARED_SECRET`, `TELEGRAM_GATEWAY_TOKEN`, `SEND_SMS_HOOK_SECRET`,
`TELEGRAM_BOT_TOKEN`…, plus `SUPABASE_SERVICE_ROLE_KEY` for the admin panel),
deploy edge functions, enable Phone auth + register the Send-SMS hook, schedule
the cron (§7.3), set Vercel envs, store submission.

**Needs third-party accounts (not just code):** real payments via
`payment-webhook` (Click/Payme merchant accounts), full Agora calls (a real Agora
project + credentials).

**Docs worth reading:** `docs/go-live-checklist.md` (ops),
`docs/phase-8-realtime-and-push.md` (calls/FCM wiring),
`docs/audit-findings.md` (known-issue backlog),
`webapp/AGENTS.md` (Next.js 16 warning), `CLAUDE.md` (terse project map).
