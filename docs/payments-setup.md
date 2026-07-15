# Payments setup (Rahmat + Payme + Click) — the go-live ops steps

Yolla charges **directly per vacancy** (no wallet): the 1st vacancy is free, and
from the 2nd onward the employer picks a tier (Standart 39 900 / Brend 79 900 /
Premium 99 900), pays via **Rahmat**, **Payme** or **Click**, and paying
publishes the draft vacancy with its tier.

All of the payment **code is in place** — four Supabase edge functions
(`payme-merchant`, `click-merchant`, `rahmat-invoice`, `rahmat-merchant`), the
order machinery (migrations `0063`, `0064`, `0065`), and the client checkout
flows. **The only thing left is credentials + registration** below. Until the
secrets are set, every function **fails closed** (Payme returns an auth error,
Click and Rahmat return "not configured").

**Rahmat is Multicard's white-label rail:** its hosted checkout lets the payer
choose among Uzcard/Humo/Visa/MC and the wallet apps (Payme, Click, Uzum) in a
single sheet — so a single "Rahmat" button on our side covers most local
rails. Payme and Click stay wired as direct-provider fallbacks.

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
RAHMAT_BASE_URL            = https://mesh.multicard.uz/       # prod (or dev-mesh for sandbox)
RAHMAT_APPLICATION_ID      = <Multicard application id>
RAHMAT_SECRET              = <Multicard merchant secret>
RAHMAT_STORE_ID            = <Multicard store id>
RAHMAT_CALLBACK_SCHEME     = webhooks                         # or 'success' — ask the Multicard integrator
SUPABASE_SERVICE_ROLE_KEY  = <service role key>              # already set for other fns
```
Client-side (public — the checkout URL only needs the merchant/service ids, never
the secret keys). For Rahmat the client holds nothing but an on/off flag; the
`rahmat-invoice` edge fn talks to Multicard using the server-side secret:
```
NEXT_PUBLIC_PAYME_MERCHANT_ID   = <Payme merchant id>        # webapp (Vercel env)
NEXT_PUBLIC_CLICK_SERVICE_ID    = <Click service id>
NEXT_PUBLIC_CLICK_MERCHANT_ID   = <Click merchant id>
NEXT_PUBLIC_RAHMAT_ENABLED      = 1                          # empty/0 → hide Rahmat button
```
Mobile (Flutter) takes the same public ids via `--dart-define` at build time
(plus the public web origin the gateway returns to):
```
flutter build apk \
  --dart-define=PAYME_MERCHANT_ID=<Payme merchant id> \
  --dart-define=CLICK_SERVICE_ID=<Click service id> \
  --dart-define=CLICK_MERCHANT_ID=<Click merchant id> \
  --dart-define=RAHMAT_ENABLED=1 \
  --dart-define=WEB_BASE_URL=https://yollla.uz
```
Until these are set, the mobile pay screen shows "online payment isn't set up
yet" and the web checkout reports `unconfigured` — nothing is charged.

## 2. Deploy the functions
```
supabase functions deploy payme-merchant  --no-verify-jwt
supabase functions deploy click-merchant  --no-verify-jwt
supabase functions deploy rahmat-merchant --no-verify-jwt
supabase functions deploy rahmat-invoice
```
Three of the four are registered `verify_jwt = false` in
`supabase/config.toml` — Payme/Click/Rahmat callbacks arrive with no user JWT
and are gated by provider signatures. **`rahmat-invoice` is different:** it
requires a Yolla user JWT (the caller must own the order they're paying for)
and stays at the default `verify_jwt = true`.

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

**Rahmat / Multicard (Merchant cabinet → your store):**
- **Callback URL:**
  `https://<project-ref>.supabase.co/functions/v1/rahmat-merchant`
  (Multicard posts JSON or form-encoded here; we accept both).
- **Signature scheme:** either the Mesh **Webhooks** scheme
  `sha1(uuid + invoice_id + amount + secret)` (the default — set
  `RAHMAT_CALLBACK_SCHEME=webhooks`) or the older **Success** scheme
  `md5(store_id + invoice_id + amount + secret)`
  (`RAHMAT_CALLBACK_SCHEME=success`). Confirm with the Multicard integrator
  which one your store is configured for.
- **Invoice ID field:** we send our `promotion_orders.id` as the `invoice_id`
  when creating the invoice (via `POST {RAHMAT_BASE_URL}payment/invoice`),
  and the callback echoes it back.
- **Amount is in tiyin** (so'm × 100) at both the invoice-create and callback
  boundaries.

### Sandbox creds (Multicard dev test stand)

Non-production values Multicard hands out for smoke testing; put them in the
Supabase secrets while pointing `RAHMAT_BASE_URL` at the dev host:

```
RAHMAT_BASE_URL       = https://dev-mesh.multicard.uz/
RAHMAT_APPLICATION_ID = rhmt_test
RAHMAT_SECRET         = Pw18axeBFo8V7NamKHXX
RAHMAT_STORE_ID       = 6
```

Test card that runs through the sandbox checkout:

```
PAN     : 8600533364098829
Expiry  : 06/28
OTP SMS : 112233
```

## 4. Sandbox test (before flipping to production)
- Payme: use the sandbox merchant + the Payme test-suite; it walks
  CheckPerformTransaction → CreateTransaction → PerformTransaction (and the
  Cancel/Check paths). A successful PerformTransaction must publish the draft
  vacancy.
- Click: use the Click test service; a Prepare (correct `sign_string`) then a
  Complete with `error=0` must publish the vacancy. A bad `sign_string` must
  return `error = -1`.
- Rahmat: with the sandbox secrets above, post a draft vacancy → tap "Rahmat
  orqali to'lash" → the app opens Multicard's dev-mesh hosted checkout → enter
  the sandbox card + OTP `112233`. Multicard posts the callback and the
  vacancy must flip to `status='open'`. A re-delivered callback must return
  `{ok:true, idempotent:true}` and leave the order unchanged. A tampered
  signature must return `401 bad_signature` (nothing written to the DB).

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
