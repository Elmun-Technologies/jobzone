# Yolla (repo: `jobzone`)

A mobile-first job marketplace for Uzbekistan, with Uzbek, Russian, and English
localization. One **Supabase** backend serves a **Flutter** mobile app and a
**Next.js 16** public marketplace and admin panel.

The display brand is Yolla; the Dart package remains `jobzone` and the native
app ID remains `io.jobzone.jobzone`.

## Start here

Clone the repository (GitHub access is required for a private repository):

```bash
git clone https://github.com/Elmun-Technologies/jobzone.git
cd jobzone
```

Follow [CONTRIBUTING.md §3](CONTRIBUTING.md#3-getting-started) for tool
installation, mobile setup, and backend configuration. You only need the tools
for the client you want to work on.

### Quickest check: web tests and production build (no credentials)

Install **Node.js 22.13+ (22.x)** and **pnpm 10** first, as described in the guide.
From the repository root:

```bash
cd webapp
pnpm install --frozen-lockfile
pnpm typecheck
pnpm lint
pnpm test
pnpm build
```

For local development, run `pnpm dev` and open <http://localhost:3000> (redirects
to `/uz`). Without Supabase variables, pages render empty states and auth is
disabled: **there is no demo data**. To use live data, copy
`webapp/.env.example` to `webapp/.env.local`, fill in the Supabase URL and public
anon key, and restart the server. See the [web guide](webapp/README.md).

### Mobile tests (no credentials or device)

Install **Flutter 3.44.2**, which includes Dart 3.12 and matches CI. From the
repository root:

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed $(git ls-files '*.dart')
```

To run the app, configure `env/dev.json` and an Android/iOS device as described
in [the mobile setup](CONTRIBUTING.md#32-run-the-mobile-app). A bare
`flutter run` does **not** start an offline demo: without Supabase configuration,
the app shows a misconfigured-build screen in debug, profile, and release.

## Repository map

| Path | Contents |
|---|---|
| `lib/`, `test/` | Flutter app and unit/widget tests |
| `webapp/` | Next.js marketplace, admin panel, and Vitest tests |
| `supabase/` | Versioned schema, RLS, triggers, storage, edge functions, seed |
| `env/` | Mobile configuration templates (real files are gitignored) |
| `docs/` | Deployment, integrations, and onboarding audit |
| `.github/workflows/` | Flutter/web checks and deployment workflows |

Both clients read jobs/search from the shared Postgres `job_feed` view.
**Meilisearch is legacy-optional**, not a prerequisite for normal development.
Mocks exist only as unit-test fixtures; booted apps use the backend or empty/error
states. Never put service-role keys or edge-function secrets in client config.

## Further reading

- [Developer guide](CONTRIBUTING.md): architecture, setup, admin, testing
- [Setup audit](docs/setup-audit.md): reproduced failures, corrections, limits
- [Go-live checklist](docs/go-live-checklist.md): production operations (not needed for tests)
- [Web deployment](docs/web-app-deploy.md)
- [Calls and push](docs/phase-8-realtime-and-push.md)
