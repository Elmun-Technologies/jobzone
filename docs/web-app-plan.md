# Jobzone Web (Next.js) — 100% Implementation Plan

> **Status:** AWAITING APPROVAL. This plans a **separate Next.js web application** that shares
> the existing Supabase backend, serving **both** job-seekers and employers, built in
> **phases** (each its own draft PR). Decision confirmed with the user:
> architecture = full separate Next.js app · audience = both equally · scope = phased,
> highest-ROI screens first.

---

## Context — why a separate web app

The Jobzone mobile app (Flutter) is feature-complete: 49 screens, employer + seeker suites,
monetization, trust/verification, maps, chat, AI assist, all in uz/ru/en. It already builds
for web (`flutter build web` → GitHub Pages), **but**:

- Flutter web renders to a **canvas (CanvasKit)** — Google cannot index the content. For a
  job board, organic job discovery via Google Search (and the **Google Jobs** widget) is a
  primary growth channel, so this is a hard limitation.
- URLs are **hash-based** (`/#/jobs/123`) and there is **zero responsive layout** — desktop
  users see a stretched mobile UI.

A purpose-built **Next.js** app fixes both: server-rendered, SEO-perfect public pages
(JSON-LD `JobPosting` → Google Jobs), proper desktop layouts for recruiters working on a
keyboard, and a fast, shareable, link-friendly experience — while **reusing the entire
Supabase backend unchanged** (verified below). The mobile Flutter app stays as-is; the two
clients share one backend and one database.

---

## Architecture

| Concern | Choice | Notes |
|---|---|---|
| Framework | **Next.js (App Router, React Server Components)** | SSR/ISR for SEO; RSC for fast public pages |
| Language | **TypeScript** | DB-typed via generated Supabase types |
| Styling | **Tailwind CSS + shadcn/ui** (Radix) | Themed to Jobzone indigo `#3A36DB`; dark mode; accessible primitives |
| Data/auth | **Supabase** via `@supabase/ssr` | Cookie-based session (server + client components); RLS protects everything |
| Search | **Reuse `search-jobs` edge function** | POST, no auth, returns Meili hits + facets |
| i18n | **next-intl**, locale-prefixed routes | `uz` (default), `ru`, `en`; hreflang tags; ARB-style parity check |
| Realtime | **Supabase Realtime** (client components) | Chat + notifications |
| Maps | **MapLibre GL / react-leaflet** (OSM tiles) | Mirrors the Flutter web OSM path; explore map |
| Hosting | **Vercel** | Custom domain; ISR for public pages; preview deploys per PR |
| Location in repo | **`webapp/` subdirectory** | Does NOT conflict with Flutter's `web/`; Vercel root dir = `webapp`; own CI workflow |

**Why `webapp/` (not a separate repo or monorepo restructure):** keeps the Flutter app
byte-for-byte unchanged, the GitHub scope is this one repo, and Vercel's "Root Directory"
setting points cleanly at `webapp/`. No Flutter files move.

**Auth/role parity (mirror the Flutter guard):** the Flutter app enforces
`onboarding → auth → role choice → setup → app`, then role-gates seeker vs employer
(`lib/app/router/guards.dart` `resolveRedirect`). The web mirrors this in `middleware.ts` +
server-side session checks. **One account = one role** (job_seeker / employer), chosen at
registration — honored exactly as on mobile (`profiles.role`).

---

## Backend reuse — verified contract (little/no migration needed)

Confirmed against `supabase/migrations/*` and `supabase/functions/*`:

- **Anonymous (logged-out) SELECT already enabled** on every table the public pages need —
  no new migration required for the SEO surface:
  - `jobs` (`using (status = 'open')`), `companies` (`using (true)`), `job_categories`,
    `company_reviews`, `company_gallery`, `company_people` — all readable by `anon`.
  - `job_feed` view is `security_invoker=true` over those tables → anon reads propagate
    correctly. Latest definition (migration `0030`) exposes everything a public job page +
    `JobPosting` JSON-LD needs: `title, description, responsibilities, requirements,
    benefits, salary_min/max, currency, salary_period, company_name, company_logo_url,
    company_is_verified, category_name, city, country, lat, lng, job_type, working_model,
    experience_level, skills_required, posted_at, expires_at, boost_active, …`.
- **`search-jobs` edge function** — `POST`, **no auth**, body `{ q, filters[], sort[], limit,
  offset, facets[] }` → returns `{ hits[], nbHits, facetDistribution, processingTimeMs }`;
  always constrains to `status="open"`. The web search box/filters reuse it directly.
- **Storage**: `avatars`, `company-media`, `intro-videos` are **public** (direct URLs — used
  on public pages); `resumes`, `chat-attachments` are **private** (signed URLs / participant-
  gated — used in authenticated flows only).
- **Auth providers**: email/password, **Google OAuth**, email OTP — all reusable. Go-live
  needs the **web redirect URLs** added in Supabase (`site_url` + `additional_redirect_urls`)
  and a **Google OAuth web client ID**.
- **Other edge functions** (`notify-dispatch`, `push-dispatch`, `meili-sync`,
  `send-notification`, `payment-webhook`, etc.) are server-only (`EDGE_SHARED_SECRET`) — the
  web never calls them directly; it only writes rows (e.g. an application, a message) and the
  existing DB triggers fan out.

**The one small gap → a tiny migration in Phase 1:** `profiles_public` is `security_invoker=
true` over an authenticated-only `profiles` table, so **anon cannot read it**. The public
company **"People/Team" tab** and **review author names** need it. Fix: recreate
`profiles_public` without `security_invoker` (or add an `anon` SELECT policy limited to the
public-safe columns it already projects: `id, full_name, headline, avatar_url, cover_url,
city, country, is_open_to_work`). Low risk, append-only.

---

## Phases (each = one draft PR → review → merge → next)

### Phase 0 — Foundation / scaffold
**Goal:** a deployable, themed, i18n+auth-wired Next.js skeleton on Vercel.
- `webapp/` Next.js App Router project: TypeScript, Tailwind + shadcn/ui themed to the
  Jobzone palette (indigo `#3A36DB`, pill radii, spacing scale mirrored from
  `lib/design_system/theme/app_spacing.dart`), light/dark.
- Supabase wiring: `@supabase/ssr` server + browser clients, `middleware.ts` (session
  refresh), generated DB types (`supabase gen types typescript` → `lib/database.types.ts`).
- next-intl: `uz`/`ru`/`en`, locale-prefixed routing (`/[locale]/…`), message catalogs +
  a Vitest **parity test** (mirrors the Flutter `arb_parity_test.dart`).
- App shell: responsive header (logo, global search, locale + theme switch, auth-state
  menu), footer; a `Container`/max-width primitive; loading/empty/error/skeleton components.
- Tooling: ESLint + Prettier, Vitest, Playwright, a **CI workflow scoped to `webapp/`**
  (typecheck · lint · test · build), Vercel project config.
- **Deliverable:** skeleton home page live on a Vercel preview URL.

### Phase 1 — Public job board + SEO  *(highest ROI — the reason for Next.js)*
**Goal:** a Google-indexable, shareable public job board (no login required).
- Public, SSR/ISR pages:
  - `/[locale]` — landing: value prop, big search box, featured/recent jobs, category grid.
  - `/[locale]/jobs` — browse + filter + search (reuse `search-jobs`; facets → filter UI;
    pagination/infinite scroll), **desktop two-column** (filters sidebar + results).
  - `/[locale]/jobs/[id]` — job details (SSR) with `generateMetadata` (title/desc/OG/Twitter)
    + **JSON-LD `JobPosting`** (→ Google Jobs) + apply CTA gated behind sign-in.
  - `/[locale]/companies/[id]` — public company page (SSR) + `Organization` JSON-LD + open
    jobs, about, reviews, gallery, team (needs the `profiles_public` migration above).
  - `/[locale]/categories` + `/[locale]/category/[slug]` — SEO category landing pages.
- Infra: dynamic **`sitemap.xml`** (all open jobs + companies + categories), **`robots.txt`**,
  dynamic **OG images** (`@vercel/og`), hreflang alternates, ISR revalidation.
- **Migration:** `profiles_public` anon read (the one gap).
- **Deliverable:** public, indexable job board; jobs eligible for the Google Jobs widget.

### Phase 2 — Auth + seeker account
**Goal:** seekers can fully use the product on web.
- Auth: sign in / sign up / Google OAuth / email OTP verify / password reset; **role choice
  at registration**; complete profile. `middleware.ts` route protection mirroring
  `resolveRedirect`.
- Seeker authenticated area (desktop-adapted):
  - **Apply** to a job (CV upload → `resumes` bucket signed URL, cover letter, dynamic
    screening questions; honors `require_cover_letter`/`allow_incomplete_resume`).
  - **My Applications** + status timeline; **Bookmarks**; **Notifications** center.
  - **Profile / CV builder** (the multi-section CV: experience, education, skills, projects,
    certifications, volunteer, awards, resume) — desktop edit-form + live-preview layout.
  - Seeking status, account settings, language, password.
- **Deliverable:** end-to-end seeker journey on web.

### Phase 3 — Employer suite  *(desktop is a genuine win for recruiters)*
**Goal:** employers can fully recruit on web.
- Employer onboarding (create company); **dashboard** (stat cards in a wide grid).
- **My Jobs** (status tabs, table/grid, actions); **Post/Edit job** — the large multi-step
  form, which shines as a desktop multi-column wizard (salary, schedule, screening Qs, etc.).
- **Applicants** inbox (cross-job + per-job) — the high-value **data-table** layout: sticky
  filter sidebar, status pipeline; **applicant detail** (resume view, screening answers,
  status timeline with interview/offer/reject actions → writes
  `application_status_history`, never `current_status` directly).
- **Company management** (edit, gallery upload → `company-media`, people/recruiters).
- **Monetization**: promote sheet, checkout, promotions history (record-only orders, mirroring
  mobile).
- **Deliverable:** end-to-end employer journey on web.

### Phase 4 — Realtime chat + notifications + maps + polish
**Goal:** feature parity + production polish.
- **Chat** list + detail via Supabase Realtime (typing, read receipts, attachments →
  `chat-attachments` signed URLs); **notifications** real-time + settings.
- **Explore map** (MapLibre/Leaflet, OSM tiles) — clustered job markers + salary pills,
  map/list toggle, near-me (browser geolocation).
- Cross-cutting: accessibility (WCAG AA), **Core Web Vitals** tuning, full uz/ru/en + dark-
  mode audit, analytics, robust empty/error/loading states everywhere.
- **Deliverable:** polished, feature-complete web app for both audiences.

---

## Cross-cutting standards

- **SEO**: every public page has `generateMetadata`; `JobPosting` + `Organization` JSON-LD;
  `sitemap.xml`/`robots.txt`; OG images; hreflang; ISR. Validate with Google Rich Results
  Test + Search Console.
- **Design parity**: mirror the Flutter tokens (colors, spacing 4/8/12/16/24/32/48, radii,
  the indigo brand) into the Tailwind theme so web and mobile feel like one product.
- **Data layer**: typed Supabase queries via generated types; domain mappers from `job_feed`/
  `profiles_public`/etc. into TS types (mirror the Flutter `fromMap` shapes).
- **Testing**: Vitest (unit: mappers, i18n parity, utils), Playwright (e2e: public browse →
  job → sign-in-gated apply; employer post-job → applicant status), typecheck + lint + build
  in CI (scoped to `webapp/`). Keeps the existing Flutter CI untouched.
- **Security**: anon key only (public, RLS-protected); resumes/chat via signed URLs; never
  expose service-role or Meili admin keys to the client; reuse the existing edge-function
  gates.

---

## Go-live checklist (user steps, mostly Phase 0–1)
- Vercel project → Root Directory `webapp`, env vars `NEXT_PUBLIC_SUPABASE_URL` +
  `NEXT_PUBLIC_SUPABASE_ANON_KEY`, custom domain.
- Supabase Auth: add the web domain to `site_url` + `additional_redirect_urls`; create a
  **Google OAuth web client** (separate from the mobile one) and add its redirect.
- Submit `sitemap.xml` to Google Search Console; verify `JobPosting` rich results.

## Verification (per phase)
`pnpm typecheck` → `pnpm lint` → `pnpm test` (Vitest) → `pnpm build` → Playwright e2e →
Lighthouse (Performance/SEO/A11y ≥ 90 on public pages). Manual: public pages render server-
side (view-source shows real HTML + JSON-LD), auth + role gating works, seeker and employer
journeys complete end-to-end, uz/ru/en + dark mode clean.

---

## Open question carried to build time
Locale URL strategy: **uz unprefixed vs all-prefixed.** Recommendation: prefix all
(`/uz`, `/ru`, `/en`) with `uz` as default + hreflang — cleanest for SEO and unambiguous
canonical URLs. Revisit if the user prefers an unprefixed default locale.
