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
The optional Vector collector is excluded because it requests privileges that
this sandbox does not permit; no sandbox security settings were changed.

## Verification and limitations

The exact commands, results, and backend compatibility findings are recorded
below. External provisioning, hosted deploys, real auth, payments, push, maps,
and native device sessions are not covered by a credential-free test/build run.
