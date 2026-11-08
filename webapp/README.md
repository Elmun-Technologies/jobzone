# Yolla Web

The Next.js web client for Yolla — a responsive, SEO-friendly site for both
job-seekers and employers, sharing the same Supabase backend as the Flutter
mobile app. See the full plan in [`../docs/web-app-plan.md`](../docs/web-app-plan.md).

## Stack

- **Next.js 16** (App Router, React Server Components) + **TypeScript**
- **Tailwind CSS v4** + design tokens themed to the Yolla volt (`#C7FB00`) on ink (`#0A0A0A`), dark mode
- **Supabase** via `@supabase/ssr` (cookie auth; RLS-protected)
- **next-intl** — `uz` (default), `ru`, `en`, locale-prefixed routes
- **Vitest** (unit) · **ESLint** · **Prettier**

## Getting started

From the repository root, install Node.js 22.13+ (22.x) and pnpm 10 as described
in [the developer guide](../CONTRIBUTING.md#31-prerequisites), then:

```bash
cd webapp
pnpm install --frozen-lockfile
cp .env.example .env.local   # fill in Supabase URL + anon key (optional in dev)
pnpm dev                     # http://localhost:3000  → redirects to /uz
```

For a credential-free verification run from `webapp/`:

```bash
pnpm typecheck && pnpm lint && pnpm test && pnpm build
```

`pnpm start` serves the production build after `pnpm build`. No Supabase or
third-party keys are required for these checks. After editing `.env.local`,
restart the server. Never expose a service-role key through `NEXT_PUBLIC_*`.

## Scripts

| Script                              | Purpose                               |
| ----------------------------------- | ------------------------------------- |
| `pnpm dev`                          | Dev server                            |
| `pnpm build` / `pnpm start`         | Production build / serve              |
| `pnpm typecheck`                    | `tsc --noEmit`                        |
| `pnpm lint`                         | ESLint (next config)                  |
| `pnpm test`                         | Vitest (incl. message-catalog parity) |
| `pnpm format` / `pnpm format:check` | Prettier write / check                |

## Structure

```
src/
  app/[locale]/      # locale-scoped routes (layout = root layout, page = home)
  components/
    layout/          # header, footer, locale switcher, theme toggle
    ui/              # button, container, loading/empty/error states
  i18n/              # next-intl routing, navigation, request config
  lib/supabase/      # browser + server clients, session refresh
  proxy.ts           # Next 16 "proxy" (was middleware): locale + session
messages/            # uz.json · ru.json · en.json (kept in parity by a test)
```

## Notes

- **Next 16 rename:** request-interception lives in `src/proxy.ts` (exporting
  `proxy`), not `middleware.ts`.
- Without Supabase env vars the app still boots; auth/session is simply
  disabled and listings are empty, not mocked. Flutter instead shows a
  misconfigured-build screen until its compile-time Supabase defines are set.
- Deployed on **Vercel** with Root Directory set to `webapp/`.
