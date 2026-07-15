# Jobzone Web — Deploy & Go-Live Checklist

The Next.js web client (`webapp/`) is feature-complete for both audiences. This
is the step-by-step to put it live. It shares the **existing Supabase backend**
— no schema changes are required beyond what's already merged.

## 1. Vercel project
- New Vercel project from this repo → **Root Directory = `webapp`**.
- Framework preset: Next.js (auto-detected). Build = `next build` (default).
- Environment variables (Production + Preview):
  - `NEXT_PUBLIC_SUPABASE_URL` — the Supabase project URL
  - `NEXT_PUBLIC_SUPABASE_ANON_KEY` — the public anon key (RLS-protected)
  - `NEXT_PUBLIC_SITE_URL` — the canonical origin, e.g. `https://jobzone.uz`
    (used for canonical URLs, OG tags, and `sitemap.xml`)
- Add a custom domain (recommended for SEO over a `*.vercel.app` URL).

## 2. Supabase Auth (so sign-in works on the web origin)
In the Supabase dashboard → **Authentication → URL Configuration**:
- **Site URL**: the production origin (e.g. `https://jobzone.uz`).
- **Redirect URLs**: add `https://jobzone.uz/auth/callback` and, for previews,
  `https://*.vercel.app/auth/callback`.
- **Google provider**: create a **separate Google OAuth *web* client** (the
  mobile app uses its own), set its redirect to
  `https://<project>.supabase.co/auth/v1/callback`, and paste the client ID /
  secret into Supabase → Auth → Providers → Google.

## 3. Make sure the project is reachable + seeded
- The Supabase project must be **active** (free-tier projects pause after
  inactivity — restore it). A paused project fails DNS, so pages render empty.
- Apply migrations if not already: `supabase db push`.

## 4. SEO
- After the first deploy, submit `https://jobzone.uz/sitemap.xml` to **Google
  Search Console**.
- Validate a job page with Google's **Rich Results Test** — it should detect the
  `JobPosting` structured data (eligible for the Google Jobs experience).

## 5. Realtime chat
- Chat uses Supabase Realtime on the `messages` table, already added to the
  `supabase_realtime` publication (migration `0004`). No extra config; it works
  once the project is reachable and the user is authenticated.

## What works without any of the above
With no env vars the app still builds and runs on **mock data** (mirrors the
Flutter `Env.hasSupabase` gate), so previews and local dev never hard-fail.

## CI
`.github/workflows/webapp-ci.yml` runs `typecheck → lint → test → build` on any
`webapp/**` change, independent of the Flutter CI.

## Local development
```bash
cd webapp
pnpm install
cp .env.example .env.local   # optional; fill Supabase URL + anon key
pnpm dev                     # http://localhost:3000 → /uz
```
