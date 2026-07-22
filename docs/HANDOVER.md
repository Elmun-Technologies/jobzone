# Yollla — Topshirish va ishga tushirish qo‘llanmasi (Handover)

Bu hujjat loyihani **qabul qilib oluvchi jamoa** uchun: kod tayyor, quyidagi
qadamlar bilan mahsulotni App Store, Play Market va veb’da **jonli** qilasiz.

Chuqur texnik tafsilot: [`docs/go-live-checklist.md`](./go-live-checklist.md).

> ⚠️ **O‘zgartirmang:** ilova id’si `io.jobzone.jobzone` va Dart paket nomi
> `jobzone`. Auth deep-link va Store identifikatsiyasi shularga bog‘liq.
> Brend nomi — **Yollla** (3 ta L), domen **yollla.uz**.

---

## 0. Loyiha bir qarashda

**Yollla** — O‘zbekiston uchun ishonchli, xarita asosidagi ish bozori (ommaviy /
ishchi kasblar). Bitta **Supabase** backend + **4 qism**:

| Qism | Texnologiya | Papka |
|---|---|---|
| Web | Next.js (Vercel) | `webapp/` |
| iOS | Flutter | `lib/` |
| Android | Flutter | `lib/` |
| Admin panel | Web (Next.js) | `webapp/src/app/[locale]/admin/` |

Har biri **ish izlovchi** va **ish beruvchi**ga xizmat qiladi. Backend, RLS,
migratsiyalar, edge funksiyalar — `supabase/`.

**Holat:** kod 100% tayyor, CI yashil. Qolgani — quyidagi **ops** qadamlar.

---

## 1. Kerakli hisoblar va kalitlar (avval shularni tayyorlang)

- [ ] **Supabase** loyiha (mavjud: `nzxdnsxwxrstcrumwzwu`) — egalik/parol
- [ ] **Vercel** hisobi (veb hosting) + `yollla.uz` domeni
- [ ] **Apple Developer** ($99/yil) — iOS uchun
- [ ] **Google Play Console** ($25, bir marta) — Android uchun
- [ ] **Telegram:** @BotFather’dan bot + [Telegram Gateway](https://gateway.telegram.org) token (OTP)
- [ ] **Google OAuth** client id/secret (kirish)
- [ ] *(keyinroq)* **Firebase** loyiha — real push (FCM) uchun
- [ ] *(keyinroq)* **Click / Payme / Rahmat (Multicard)** merchant hisoblari — to‘lov

`supabase` CLI o‘rnatilgan bo‘lsin: `npm i -g supabase` yoki brew.

---

## 2. Baza — migratsiyalarni qo‘llash ✅ (birinchi qadam)

```bash
supabase link --project-ref nzxdnsxwxrstcrumwzwu
supabase db push        # 0072 gача barcha yozilmagan migratsiyalar qo‘llanadi
```

Bu content_reports (shikoyat), account_deletion, to‘lov jadvallari va
qolganlarни bazaga tushiradi. **Tekshiruv:**

```sql
select count(*) from public.content_reports;   -- jadval bor
select count(*) from job_feed;                 -- faqat ochiq, muddati o‘tmagan
```

---

## 3. Secrets (maxfiy kalitlar)

`supabase secrets set NAME=value` bilan o‘rnating. To‘liq jadval —
[go-live-checklist §2](./go-live-checklist.md#2-secrets). Minimal to‘plam:

| Kalit | Nima uchun |
|---|---|
| `EDGE_SHARED_SECRET` | Server-server funksiyalar (kuchli tasodifiy satr) |
| `TELEGRAM_GATEWAY_TOKEN` | OTP yetkazish |
| `TELEGRAM_BOT_TOKEN` | Bildirishnoma / bot |
| `TELEGRAM_WEBHOOK_SECRET` | Webhook himoyasi |
| `SEND_SMS_HOOK_SECRET` | §5 hook’dan olinadi |
| `SUPABASE_SERVICE_ROLE_KEY` | Admin panel (Vercel env’ga ham) |
| `ANTHROPIC_API_KEY` | *(ixtiyoriy)* AI matn yordami |

DB-ichki sekretlar (`private.app_secrets`) — checklist §2’dagi SQL bilan.

---

## 4. Edge funksiyalarni deploy qilish

```bash
supabase functions deploy notify-dispatch push-dispatch saved-search-alerts \
  send-sms-hook telegram-webhook telegram-channel-post delete-account \
  generate-job-content
```

To‘lov (keyinroq): `click-merchant payme-merchant rahmat-merchant rahmat-invoice payment-webhook`.

---

## 5. Supabase Auth sozlash

- **Phone** provayderни yoqing (Telegram OTP shusiz ishlamaydi).
- Dashboard → Authentication → Hooks → **Send SMS hook** → `send-sms-hook`
  funksiyasiga yo‘naltiring; hosil bo‘lgan sekretни `SEND_SMS_HOOK_SECRET`ga.
- **Google** OAuth: client id/secret + redirect URL’lar (veb + mobil deep-link
  `io.jobzone.jobzone`).
- **Email/parol** yoqilgan bo‘lsin.
- Telegram webhook’ni ro‘yxatdan o‘tkazing (checklist §3’dagi `curl`).

---

## 6. Cron (rejalashtirilган ishlar)

Supabase SQL editor’da:

```sql
select cron.schedule(
  'yolla-alerts', '*/15 * * * *',
  $$ select public.publish_due_jobs(); select public.run_saved_search_alerts(); $$
);
```

Bu har 15 daqiqada rejalashtirilган e’lonlarni chiqaradi va saqlangan
qidiruvlarga signal yuboradi.

---

## 7. Web (Vercel)

- Vercel loyiha, **root directory: `webapp/`**.
- Env (Production + Preview): `NEXT_PUBLIC_SUPABASE_URL`,
  `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` (admin),
  `NEXT_PUBLIC_SENTRY_DSN` *(ixtiyoriy)*.
- `webapp/vercel.json` region’ni **`hnd1` (Tokio)** ga bog‘lagan (Supabase bilan
  yonma-yon — tez). Domen `yollla.uz`ни ulang.
- Deploy avtomatik (main’ga push’da).

---

## 8. Mobil — build va Store’ga yuborish

### 8a. Android → Play Market

```bash
# 1) Release keystore yarating (BIR MARTA, xavfsiz saqlang!):
keytool -genkey -v -keystore ~/yollla-release.jks -keyalg RSA -keysize 2048 \
        -validity 10000 -alias yollla

# 2) android/key.properties yarating (android/key.properties.example dan):
#    storeFile=/absolute/path/yollla-release.jks
#    storePassword=... / keyPassword=... / keyAlias=yollla

# 3) AAB build (Play Market shuni so‘raydi):
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://nzxdnsxwxrstcrumwzwu.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon key>
# → build/app/outputs/bundle/release/app-release.aab
```

Play Console → yangi ilova → AAB yuklang → do‘kon sahifasi (skrinshot, tavsif,
maxfiylik siyosati: `yollla.uz/privacy`) → ko‘rib chiqishga yuboring.
**Keystore’ni yo‘qotmang** — keyingi yangilanishlar shu kalit bilan imzolanadi.

### 8b. iOS → App Store

```bash
flutter build ipa --release \
  --dart-define=SUPABASE_URL=https://nzxdnsxwxrstcrumwzwu.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon key>
```

Xcode/Transporter orqali App Store Connect’ga yuklang → TestFlight → do‘kon
sahifasi → ko‘rib chiqish. Sign in with Apple, maxfiylik yorlig‘i
(`PrivacyInfo.xcprivacy`) allaqachon ulangan.

### 8c. Xaritalar / push

- **Yandex MapKit key** kod’da (app-id bilan cheklangan) — Yandex kabinetida
  `io.jobzone.jobzone`ga cheklang.
- **FCM (ixtiyoriy):** Firebase loyihadan `google-services.json` (Android) va
  `GoogleService-Info.plist` (iOS) qo‘shing — `docs/phase-8-realtime-and-push.md`.

---

## 9. Ishga tushgandan keyin — smoke testlar

1. **E’lon → ko‘rinish:** ish beruvchi vakansiya joylaydi → mobil va veb’da,
   o‘z kategoriyasida darhol chiqadi.
2. **Telegram OTP:** raqam kiriting → kod Telegram’da keladi → tasdiqlash.
3. **Ariza:** izlovchi ariza beradi → beruvchi ko‘radi; status o‘zgarsa —
   izlovchiga bildirishnoma.
4. **Saqlangan qidiruv:** obuna → mos vakansiya → signal keladi.
5. **Hamyon:** to‘ldirish `pending` yozuv sifatida tushadi.
6. **Xarita:** ishlar maosh-pin bo‘lib xaritada chiqadi.

---

## 10. Monitoring va analitika (ishga tushgach)

- **Sentry** — xatolarni kuzatish (`NEXT_PUBLIC_SENTRY_DSN` env).
- **Yandex Metrica · PostHog · Meta Pixel · Vercel Analytics** — cookie
  roziligidan keyin ishlaydi (GDPR banner ulangan).
- **Supabase Dashboard** — DB yuki, so‘rov tezligi, log.

---

## 11. Kim nima qiladi (topshirish)

| Rol | Qadamlar |
|---|---|
| **Backend / DevOps** | §2 (db push), §3 (secrets), §4 (edge deploy), §5 (auth), §6 (cron) |
| **Web** | §7 (Vercel env + domen) |
| **Mobil** | §8 (keystore, build, App Store + Play Market) |
| **Marketing / kontent** | Do‘kon sahifalari, skrinshotlar, birinchi kompaniyalar |
| **Admin** | `/admin` — moderatsiya, moliya, kategoriya, broadcast |

---

## 12. Xarajatlar (taxminiy)

- **Boshlanish (MVP):** ~$0–15/oy (asosan bepul tier’lar).
- **O‘sish:** ~$90–150/oy (Supabase Pro, Vercel Pro, Sentry, AI).
- **Yillik/bir martalik:** Apple $99/yil · Google Play $25 · domen ~$20/yil.
- **To‘lovlar:** tranzaksiyadan ~1–3% (oylik fiks yo‘q).

Batafsil taqdimotda (`Yollla-Presentatsiya.pdf`).

---

**Xulosa:** kod tayyor. §2 → §8 ni bajarib, Yollla’ni jonli qiling. Har bir
qadam yuqorida aniq buyruqlar bilan berilgan; chuqurroq detal —
`docs/go-live-checklist.md`.
