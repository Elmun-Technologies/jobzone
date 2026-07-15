<div align="center">

# Jobzone

**Find your next job.** A production-grade job-finder mobile app built with **Flutter**, **Supabase**, and **Meilisearch** — with real-time chat, full **Uzbek / Russian / English** localization, and light/dark theming.

</div>

---

## Highlights

- **~60 screens** across auth, jobs, search, applications, profile/CV, companies, chat, notifications, and account management.
- **Offline-first demo**: runs end-to-end on built-in mock data with **no backend** — and activates Supabase + Meilisearch the moment env credentials are added (`Env.hasSupabase` gates every call).
- **Clean, feature-first architecture** (`data / domain / presentation` per feature) with Riverpod state management and go_router navigation.
- **Backend-as-code**: the entire Postgres schema, RLS, triggers, storage buckets, and Edge Functions live in `supabase/` as versioned migrations.
- **Quality bar**: `flutter analyze` clean, 50+ unit/widget tests, `dart format` enforced — gated in CI on every PR.

## Feature tour

| Area | What's included |
|------|-----------------|
| **Onboarding & Auth** | Splash/session-restore · welcome · 3-slide onboarding · email sign-in / sign-up / OTP verify / password reset / complete-profile · preference setup (job type, experience, working model, titles) · location & notification permission flows |
| **Home & Jobs** | Suggested + recent feeds · job details (About/Company/Reviews tabs) · bookmark toggle · see-all |
| **Search** | Meilisearch-backed Explore + debounced Search · filters (type/level/model/category/salary/remote/verified) · sort |
| **Applications** | Apply (cover letter + default CV) → success · My Applications · status timeline |
| **Profile / CV** | Read view + full editing for Experience, Education, Projects, Certifications, Volunteer, Awards, Skills, About, Contact Info, and Resume upload |
| **Companies** | Company details with Open Jobs / About / Reviews / People / Gallery tabs · intro-video player · full-screen gallery viewer · write-a-review |
| **Chat & Notifications** | Real-time conversations (Supabase Postgres Changes) · message composer · UI for voice/video calls · notifications list + per-channel settings |
| **Account** | Personal info · analytics dashboard · job-seeking status · settings · password manager · help center · privacy policy · invite friends · logout |

## Tech stack

- **Flutter** (Dart 3), Material 3, iOS + Android
- **Riverpod** for state/DI · **go_router** (`StatefulShellRoute`) for navigation
- **Supabase** — Auth, PostgreSQL (+RLS), Storage, Realtime
- **Meilisearch** for job search (synced from Postgres via an Edge Function; the client only ever talks to a scoped proxy)
- **flutter_localizations** + ARB (uz/ru/en), runtime locale switch
- Design tokens as a `ThemeExtension` (`JzColors`), royal-indigo accent `#3A36DB` (Figma reference)

## Getting started

```bash
flutter pub get
flutter gen-l10n          # generate localizations
flutter run               # runs in offline/mock mode out of the box
```

The app boots straight into the shell with realistic mock data — no setup required.

### With a real backend

1. Provision a Supabase project and apply the schema:
   ```bash
   supabase db reset                                 # migrations/* + seed.sql
   supabase functions deploy meili-sync meili-reindex search-jobs send-notification
   ```
2. Deploy Meilisearch (Railway/Render) and set the Edge Function secrets (Meili host + admin key — never shipped to the client).
3. Create `env/dev.json` (gitignored — see `env/dev.example.json`):
   ```json
   { "SUPABASE_URL": "...", "SUPABASE_ANON_KEY": "...", "SEARCH_PROXY_URL": "..." }
   ```
4. Run against it:
   ```bash
   flutter run --dart-define-from-file=env/dev.json
   ```

## Project structure

```
lib/
├─ app/            MaterialApp, router (shell + guards), routes
├─ core/           config (env/flavors), supabase client, storage, utils
├─ design_system/  theme tokens + reusable widgets (buttons, inputs, feedback…)
├─ localization/   ARB files (en/ru/uz) + locale controller
├─ shared/         enums, app-flags, shared widgets
└─ features/       auth · onboarding · preferences · permissions · home · jobs ·
                   search · applications · profile · companies · reviews · chat ·
                   notifications · calls · account · splash
supabase/
├─ migrations/     0001…0008  (schema, RLS, triggers, buckets, devices)
├─ functions/      meili-sync · meili-reindex · search-jobs · send-notification ·
                   agora-token · push-dispatch
└─ seed.sql
docs/
└─ phase-8-realtime-and-push.md   real calls (Agora) + push (FCM) wiring guide
```

## Localization

Three locales (`en`, `ru`, `uz`) live in `lib/localization/l10n/*.arb` and switch at runtime from the Language screen. Run `flutter gen-l10n` after editing. A test (`test/localization/arb_parity_test.dart`) enforces that every locale defines the same keys.

## Testing

```bash
flutter analyze
flutter test
dart format --set-exit-if-changed lib test
```

CI (`.github/workflows/ci.yml`) runs all of the above on every PR.

## Roadmap status

Phases 0–7 are **complete** (foundation → auth → jobs/profile → search → applications → CV editing → companies/media → chat/notifications → account hub), plus polish (shimmer skeletons, error-states-with-retry, accessibility). **Phase 8** (real WebRTC/Agora calls + FCM push) is **scaffolded** behind provider seams — see [`docs/phase-8-realtime-and-push.md`](docs/phase-8-realtime-and-push.md) for the drop-in wiring guide.
