# Jobzone

A production-grade **job-finder** mobile app built with **Flutter** + **Supabase** + **Meilisearch**, with full **Uzbek / Russian / English** localization and real-time chat.

> This repository is being built in phases. **Phase 0 (this foundation)** ships the project scaffold, design system, localization, the bottom-navigation shell, and the complete backend-as-code (Supabase schema + Meilisearch sync). Feature modules (auth, jobs, search, profile, chat, …) land in subsequent PRs.

## Tech stack

| Layer | Technology |
|---|---|
| Mobile | Flutter (Dart 3), Material 3 |
| State / DI | Riverpod 3 |
| Routing | go_router (`StatefulShellRoute`) |
| Backend | Supabase — Auth, PostgreSQL, Storage, Realtime |
| Search | Meilisearch (synced from Postgres via Edge Functions) |
| i18n | `flutter_localizations` + `intl` (ARB), runtime locale switch |

## Project structure

```
lib/
  app/            MaterialApp.router, GoRouter, bottom-nav shell
  core/           config (env/flavors), supabase client, storage
  localization/   ARB files (en/ru/uz), locale controller, generated/
  design_system/  theme tokens (colors/typography/spacing) + widgets
  shared/         cross-feature enums, models, widgets
  features/<f>/   feature slices: data / domain / presentation
supabase/
  migrations/     full Postgres schema + RLS + triggers + storage buckets
  functions/      Edge Functions: meili-sync, meili-reindex, search-jobs, send-notification
  seed.sql        reference data (job categories)
```

Each feature is a vertical slice: `presentation` (pages + Riverpod controllers) → `domain` (immutable models + repository interfaces) → `data` (Supabase/Meili implementations).

## Getting started

### 1. Prerequisites
- Flutter 3.44+ (Dart 3.12+)
- [Supabase CLI](https://supabase.com/docs/guides/cli) + Docker (for the local backend)
- [Meilisearch](https://www.meilisearch.com/docs/learn/getting_started/installation) (Docker is fine)

### 2. Install & generate
```bash
flutter pub get
flutter gen-l10n        # generates lib/localization/generated/ (gitignored)
```

### 3. Configure env
Copy the templates and fill in your values (do **not** commit the non-example files):
```bash
cp env/dev.example.json env/dev.json
```
```jsonc
{
  "FLAVOR": "dev",
  "SUPABASE_URL": "https://<project-ref>.supabase.co",
  "SUPABASE_ANON_KEY": "<publishable key>",
  "SEARCH_PROXY_URL": "https://<project-ref>.functions.supabase.co/search-jobs"
}
```
> The app **boots without a backend** too (offline mode) — handy for UI work and CI.

### 4. Run
```bash
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=env/dev.json
```

## Backend (Supabase)

```bash
supabase start                 # local Postgres + Auth + Storage + Realtime
supabase db reset              # applies migrations/ + seed.sql
supabase functions serve       # serve Edge Functions locally
```

**Meilisearch sync.** `jobs` rows are mirrored into a Meilisearch `jobs` index. In production set these DB settings (or use the Database Webhooks UI) so the `meili-sync` function is called on changes:
```sql
alter database postgres set "app.meili_webhook_url"  = 'https://<ref>.functions.supabase.co/meili-sync';
alter database postgres set "app.edge_shared_secret" = '<shared-secret>';
```
Function secrets required: `MEILI_HOST`, `MEILI_ADMIN_KEY`, `MEILI_SEARCH_KEY`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `EDGE_SHARED_SECRET`. Run `meili-reindex` once (and nightly via `pg_cron`) to (re)build the index.

## Localization

Strings live in `lib/localization/l10n/app_{en,ru,uz}.arb`. After editing, run `flutter gen-l10n`. The in-app **Profile → Language** screen switches locale at runtime (no restart).

## Testing

```bash
flutter analyze
flutter test
dart format --set-exit-if-changed $(git ls-files '*.dart')
```
CI (`.github/workflows/ci.yml`) runs all of the above on every push/PR.

## Roadmap

Phase 1 Auth & onboarding · Phase 2 Home/Jobs/Profile · Phase 3 Search/Filter/Explore · Phase 4 Applications & profile editing · Phase 5 Companies & media · Phase 6 Chat & notifications · Phase 7 Account hub & polish · Phase 8 (later) real video/voice calls + push.
