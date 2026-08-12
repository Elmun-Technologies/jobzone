# Jobzone Production Deployment Guide

This guide outlines the mandatory steps to deploy the **Jobzone (Yollla)** platform to a live production environment.

## 1. Supabase Backend Setup

1. **Reset and Apply Migrations**:
   ```bash
   supabase db reset
   ```
   This applies all schema migrations from `0001` through `0085`, including RLS policies, triggers, custom types, and secure views.

2. **Configure Private Secrets**:
   Insert required production secrets into the locked `private.app_secrets` table (migration `0040`):
   ```sql
   insert into private.app_secrets (name, value) values
     ('telegram_gateway_token', '<your_telegram_gateway_token>'),
     ('notify_dispatch_url', 'https://<project-ref>.functions.supabase.co/notify-dispatch'),
     ('lifecycle_email_url', 'https://<project-ref>.functions.supabase.co/lifecycle-email'),
     ('telegram_channel_post_url', 'https://<project-ref>.functions.supabase.co/telegram-channel-post'),
     ('edge_shared_secret', '<your_secure_random_string>');
   ```

## 2. Deploy Edge Functions

Deploy all Supabase Edge Functions with versioned secrets:
```bash
supabase functions deploy meili-sync meili-reindex search-jobs send-notification payme-merchant click-merchant payment-webhook notify-dispatch lifecycle-email telegram-channel-post
```

Set required Edge Function secrets:
```bash
supabase secrets set EDGE_SHARED_SECRET="<your_secure_random_string>"
supabase secrets set PAYME_KEY="<your_payme_merchant_key>"
supabase secrets set CLICK_SERVICE_ID="<your_click_service_id>"
supabase secrets set CLICK_SECRET_KEY="<your_click_secret_key>"
supabase secrets set MEILI_HOST="<your_meilisearch_host>"
supabase secrets set MEILI_ADMIN_KEY="<your_meilisearch_admin_key>"
```

## 3. Payment Gateway Configuration

* **Payme**: Register your `payme-merchant` function URL in the Payme Merchant Cabinet. Configure `account.order_id` as the transaction identifier field.
* **Click**: Register both Prepare and Complete URLs pointing to your `click-merchant` function URL in the Click Merchant Portal.

## 4. Mobile & Web Apps

1. Create `env/dev.json` (or `env/prod.json`) from `env/dev.example.json`:
   ```json
   {
     "SUPABASE_URL": "https://your-project.supabase.co",
     "SUPABASE_ANON_KEY": "your-anon-key",
     "SEARCH_PROXY_URL": "https://your-project.supabase.co/functions/v1/search-jobs"
   }
   ```
2. Run Flutter app:
   ```bash
   flutter run --dart-define-from-file=env/dev.json
   ```
3. Build Next.js webapp:
   ```bash
   cd webapp && pnpm install && pnpm build
   ```


## 5. High-Scale (Million+ Users) Infrastructure Hardening

To support millions of active job seekers and employers without performance degradation, apply the following infrastructure configurations:

1. **Database Connection Pooling (PgBouncer)**:
   * Always connect your backend services and Edge Functions to PostgreSQL through Supabase's PgBouncer in **Transaction Mode** (port 6543) rather than session mode (port 5432). This prevents connection exhaustion under heavy concurrent spikes.

2. **Read Replicas**:
   * For read-heavy operations (e.g., job searches, feed browsing, category filtering), configure Supabase Read Replicas so heavy `SELECT` queries bypass the primary write database.

3. **Edge Rate Limiting & Anti-Abuse**:
   * Utilize the shared rate limiter (`_shared/rate-limit.ts`) across all critical Edge Functions (`search-jobs`, `payment-webhook`, `notify-dispatch`) to mitigate DDoS attacks and API scraping.

4. **CDN & ISR Caching**:
   * Deploy the Next.js webapp to Vercel and leverage `cache.ts` tags and Incremental Static Regeneration (ISR) to cache public catalog data at the Edge.
