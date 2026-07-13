# Payments setup (Payme + Click) — the go-live ops steps

Yolla charges **directly per vacancy** (no wallet): the 1st vacancy is free, and
from the 2nd onward the employer picks a tier (Standart 39 900 / Brend 79 900 /
Premium 99 900), pays via **Payme** or **Click**, and paying publishes the draft
vacancy with its tier.

All of the payment **code is in place** — two Supabase edge functions
(`payme-merchant`, `click-merchant`), the order machinery (migrations `0063`,
`0064`), and the client checkout redirects. **The only thing left is
credentials + registration** below. Until the secrets are set, both functions
**fail closed** (Payme returns an auth error, Click returns "Not configured").

## How it works
1. Employer publishes a 2nd+ vacancy → it is saved as a **draft**, and
   `create_listing_order(job, tier)` (migration 0063) creates a `pending`
   `promotion_orders` row and returns `{order_id, amount}`.
2. The client sends the employer to the provider's checkout, addressing our
   **`order_id`** and the tier price.
3. The provider calls our edge function; on a confirmed payment we flip the order
   to `paid`. The `apply_promotion` trigger (migration 0063) then **publishes the
   draft** (`status='open'`) and stamps its `boost_kind` (brand/premium).
4. The employer is returned to `/employer/jobs/<id>/paid`, which polls until the
   vacancy is live.

The charged amount is always re-derived **server-side from the catalog price**
(`promotion_products.price_uzs`) — a tampered client amount can never under-pay.

## 1. Secrets (Supabase → Project Settings → Edge Functions → Secrets)
```
PAYME_KEY                  = <Payme merchant key>            # Basic-auth password
CLICK_SERVICE_ID           = <Click service id>
CLICK_SECRET_KEY           = <Click secret key>
CLICK_MERCHANT_ID          = <Click merchant id>             # used by the client checkout URL
SUPABASE_SERVICE_ROLE_KEY  = <service role key>              # already set for other fns
```
Client-side (public — the checkout URL only needs the merchant/service ids, never
the secret keys):
```
NEXT_PUBLIC_PAYME_MERCHANT_ID   = <Payme merchant id>        # webapp (Vercel env)
NEXT_PUBLIC_CLICK_SERVICE_ID    = <Click service id>
NEXT_PUBLIC_CLICK_MERCHANT_ID   = <Click merchant id>
# Mobile passes the same three via --dart-define at build time.
```

## 2. Deploy the functions
```
supabase functions deploy payme-merchant --no-verify-jwt
supabase functions deploy click-merchant --no-verify-jwt
```
(They are already registered `verify_jwt = false` in `supabase/config.toml`.)

## 3. Register the endpoints with each provider
**Payme (Merchant Cabinet → your merchant → settings):**
- **Endpoint URL:** `https://<project-ref>.supabase.co/functions/v1/payme-merchant`
- **Account field:** add one field named exactly **`order_id`** (this is the
  `account.order_id` our function reads).
- Amounts are handled in **tiyin** (so'm × 100) automatically.

**Click (Cabinet → SHOP-API):**
- **Prepare URL** and **Complete URL:** both
  `https://<project-ref>.supabase.co/functions/v1/click-merchant`
  (the function routes on the `action` field: 0 = Prepare, 1 = Complete).
- The `merchant_trans_id` the client sends is our **`order_id`**.

## 4. Sandbox test (before flipping to production)
- Payme: use the sandbox merchant + the Payme test-suite; it walks
  CheckPerformTransaction → CreateTransaction → PerformTransaction (and the
  Cancel/Check paths). A successful PerformTransaction must publish the draft
  vacancy.
- Click: use the Click test service; a Prepare (correct `sign_string`) then a
  Complete with `error=0` must publish the vacancy. A bad `sign_string` must
  return `error = -1`.

## Notes
- Both endpoints return HTTP 200 with the provider's own error envelope
  (JSON-RPC for Payme, `{error, error_note}` for Click) — that's the protocol,
  not an HTTP failure.
- Idempotency + Payme's create→perform/cancel state machine live in
  `payment_transactions` (migration 0064). Re-delivered callbacks are safe.
- Refund/cancel marks the order `refunded`/`cancelled`; an already-published
  vacancy is left live (un-publishing on refund is a business decision, not
  automated).
- The old `payment-webhook` scaffold (shared-secret, marks a promotion order
  paid) stays for manual/admin confirmation and internal testing; the two
  provider functions above are the production path.
