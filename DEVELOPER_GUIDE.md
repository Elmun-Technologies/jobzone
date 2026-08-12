# Jobzone (Yollla) Developer Guide

Welcome to the **Jobzone** engineering documentation. This guide outlines the core architecture, state management conventions, database guidelines, and local development setup for developers contributing to the project.

---

## 1. Tech Stack Overview

* **Mobile App (Android / iOS):** Flutter (v3.x), Riverpod (State Management), GoRouter (Declarative Navigation).
* **Web App:** Next.js 16 (App Router), React 19, Tailwind CSS v4, `next-intl`.
* **Backend & Database:** Supabase (PostgreSQL, Row Level Security, Edge Functions in Deno/TypeScript).
* **Search & Discovery:** Meilisearch + PostgreSQL trigrams (`pg_trgm`).

---

## 2. Local Development Setup

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Elmun-Technologies/jobzone.git
   cd jobzone
   ```

2. **Supabase Local Instance**:
   ```bash
   supabase start
   supabase db reset
   ```

3. **Run Flutter App**:
   ```bash
   flutter pub get
   flutter run --dart-define-from-file=env/dev.json
   ```

4. **Run Web App**:
   ```bash
   cd webapp
   pnpm install
   pnpm dev
   ```

---

## 3. Architecture Conventions

* **State Management (Flutter):** Use Riverpod providers (`AsyncNotifierProvider` / `StateNotifierProvider`) located under `lib/features/<feature>/application/`. Avoid setState for shared business logic.
* **Database Security (RLS):** Every new table MUST have Row Level Security (RLS) enabled. Always write explicit policies using `auth.uid()` and company ownership helper functions (see migrations `0001` - `0086`).
* **Edge Functions:** Located under `supabase/functions/`. Always incorporate rate-limiting (`_shared/rate-limit.ts`) and authenticate requests using JWT tokens or shared secrets.
