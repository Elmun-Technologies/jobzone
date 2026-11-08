# Clean-checkout onboarding audit

Audited on 2026-11-08, starting at `77d7380`. The checkout had no installed web
packages or generated Flutter dependency/localization output. No project secrets
or setup script were supplied. This was a Linux sandbox with preinstalled tools,
not a newly installed operating system: tool installation links are documented,
but OS installers, Android/iOS toolchains, and store builds were not exercised.

## Findings and changes

| Original step / claim | Observed problem | Correction |
|---|---|---|
| Root README: `flutter pub get`, `flutter gen-l10n`, bare `flutter run` starts a mock demo | The README contradicts `bootstrap()` and `Env`: booted apps require Supabase URL/key. Mock repository seams are test-only. | Separate credential-free tests from configured app runs; show copying/editing `env/dev.json` before running. |
| CONTRIBUTING §3.2: release/profile builds fall back to a demo backend | `lib/core/config/env.dart` has no fallback URL/key. Missing configuration fails in every build mode. | Remove the fallback claim; document compile-time defines and rerunning after edits. |
| README omits clone, tool versions, native SDK/device setup and the Next.js client | A newcomer cannot identify prerequisites or discover the easiest test path. | Add clone instructions, installation links, independent client paths, `flutter doctor`/devices, and credential-free web checks. |
| CONTRIBUTING: Node 20+, pnpm 9+ | CI uses Node 22 and pnpm 10. Locked jsdom requires `^20.19.0 \|\| ^22.13.0 \|\| >=24.0.0`; older Node 20/22 releases do not meet it. | Recommend Node 22.13+ (22.x) and pnpm 10; use frozen installs. |
| README: Meilisearch-backed search and a required Meili deployment | Both clients' regular job search reads Postgres `job_feed`; Meilisearch functions are legacy-optional. | Remove mandatory Meili provisioning/deployment from onboarding. |
| README: provision a hosted project with `supabase db reset` | Reset targets the local stack by default, needs a running stack, and is destructive; it does not provision a hosted project. | Separate local Docker/start/reset/status from authorized hosted login/link/push/deploy. No remote mutation was attempted. |
| CONTRIBUTING: `supabase db push` / function deploy without login/link context | The instructions omit authentication, project selection and permission boundaries. | Document maintainer-only deployment, explicit login/link, development project selection and function-specific go-live configuration. |
| Web deployment guide: no env renders mock data; web README compares it with Flutter | Web readers return empty/null without config; Flutter displays a configuration error instead. | Correct both guides, explain optional variables and restarting after `.env.local` changes. |
| README and CONTRIBUTING pin historical schema ranges (`0001…0008`, `0001…0057`) | The migration guard finds 87 migrations in the audited revision. | Point at the migration directory rather than stale counts. |
| Phase-8 integration guide introduction promises offline + Meilisearch startup | Historical implementation notes conflict with current bootstrap/search. | Mark the guide as historical and link current setup/go-live instructions. |
| Formatting command in README scans directories, including generated output, and can rewrite files | The intended CI scope is tracked Dart sources. | Document a non-mutating check of tracked Dart files with `--output=none`. |

### Supabase CLI compatibility failures

With CLI **3.0.0** and a working Docker daemon:

1. Original `supabase db reset` and `supabase start -x vector` failed before
   starting containers: `[inbucket] ... is no longer supported. Use [local_smtp]
   instead.` Renamed that config section, retaining the local mail port.
2. The next start warned that `auth.email.enable_signup` is deprecated in favor
   of `auth.email.enabled`. Updated the email setting without changing the
   top-level signup policy.
3. After the section rename, startup failed with `ENOENT` for
   `templates/confirmation.html` at repository root. All five mail template
   paths now point to the tracked `supabase/templates/` directory, relative to
   the CLI project root.

The onboarding guide now names the tested CLI version instead of “latest.”
The section/key renames follow the official
[CLI v3 migration guide](https://supabase.com/docs/guides/local-development/cli/migrating-to-v3).
The optional Vector collector is excluded because it requests privileges that
this sandbox does not permit; no sandbox security settings were changed.

## Verification and limitations

The exact commands, results, and backend compatibility findings are recorded
below. External provisioning, hosted deploys, real auth, payments, push, maps,
and native device sessions are not covered by a credential-free test/build run.

### Web

- Initial toolchain: Node `24.22.2`, pnpm `10.34.9`; Next `16.2.9` from the lockfile.
- Original `cd webapp && pnpm install`: passed, without changing the lockfile.
- `pnpm typecheck`: passed. `pnpm lint`: passed.
- `pnpm test`: **19 files, 113 tests passed** without environment files/secrets.
- `pnpm build`: passed on the initial Node 24 toolchain without credentials.
- Repeated `pnpm install --frozen-lockfile`, `pnpm typecheck`, `pnpm lint`,
  `pnpm test` and `pnpm build` on **Node 22.23.4 / pnpm 10.34.9**: all passed,
  including the same 113 tests. This is the toolchain recommended by the revised
  guide (Node 22.x / pnpm 10).
- `pnpm dev`: started. HTTP smoke check: `/` returned **307** to `/uz`, and
  `/uz` returned **200** without backend configuration. This is an HTTP check,
  not a visual or authenticated-flow test.
- The dev response logs existing next-intl `INVALID_KEY` diagnostics for dotted
  message keys (`report.reason.*`, `adminReports.status.*`). The request still
  succeeds. This product-localization issue is recorded, not hidden or repaired
  as an unrelated onboarding/script change.

### Backend

- Docker `29.1.3`; Supabase CLI `3.0.0`; local PostgreSQL 15 configuration.
- After the config fixes, `supabase start -x vector` initialized the database,
  applied **all 87 migrations (`0001`–`0087`)**, and loaded `supabase/seed.sql`.
- Full startup then failed while creating service containers: the sandbox's
  Docker policy rejects the CLI's workspace bind-mount options (allowed options:
  `ro`, `rw`, or private propagation). No security-policy bypass was attempted.
  This is an environment limitation, not evidence of a SQL failure.
- A subsequent `supabase db reset` targeted the local database but failed with
  `supabase start is not running`. Full-stack readiness, reset completion and
  `supabase status` credentials are therefore **not verified** here. Do not
  mistake successful migration initialization for a running backend.
- `bash scripts/check-migrations.sh`: passed, **87 unique versions**.
- No hosted login/link/push, edge-function deploy, or production operation was
  executed; those require an explicitly selected, authorized project.

### Mobile

- Initial Flutter `3.47.9` / Dart `3.13.7`: `flutter pub get`,
  `flutter gen-l10n`, `flutter analyze`, `flutter test`, and tracked-file
  formatting checks passed; **190 tests passed**, **300 Dart files** already
  formatted. This newer SDK also auto-added platform/build analyzer exclusions.
- Repeated the documented path from a separate clean copy with the CI-pinned
  **Flutter 3.44.2 / Dart 3.12.2**: dependency resolution, localization,
  analysis, **190 tests**, and
  `dart format --output=none --set-exit-if-changed $(git ls-files '*.dart')`
  all passed. No analyzer-option migration was needed on the pinned SDK.
- The checked-in mobile lockfile is stale relative to `pubspec.yaml`:
  `flutter pub get` reports **14 dependency changes** on the pinned SDK
  (including the already-declared Yandex MapKit replacement), versus 21 on the
  newer SDK. Resolution succeeds. Generated lockfile/analyzer changes were
  discarded rather than mixing dependency changes into this onboarding PR.
- `env/dev.json` does not exist in a fresh clone and its example contains empty
  URL/key fields. The revised run instructions explicitly copy and edit it
  before referencing it. Configuration behavior was checked against `Env` and
  `bootstrap()`; an authenticated device session was not attempted.
- `flutter doctor` reports no Android SDK. An Android debug build using the
  pinned SDK failed with `No Android SDK found`. Added Android SDK/device,
  license acceptance and **JDK 21** prerequisites (matching Gradle JVM targets).
  iOS builds require macOS/Xcode/CocoaPods and were not exercised on Linux.

### Final review

An independent read-only review compared the onboarding commands, example-file
paths, manifests and CI toolchains. No additional clone-to-test/build issues
were found. `git diff --check` passed. The success criterion demonstrated here
is a credential-free test/production-build path, not full production readiness.
