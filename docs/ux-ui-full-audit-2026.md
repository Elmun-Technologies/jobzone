# Yollla — to‘liq UX/UI, arxitektura va xavfsizlik auditi

**Sana:** 2026-08-12 (yangilandi: 10/10 polish sprint)  
**Qamrov:** Android · iOS · Web · ish izlovchi · ish beruvchi · admin panel · arxitektura · tuzilish · xavfsizlik · 1 000 000+ foydalanuvchi  
**Usul:** joriy kod holati (migratsiyalar 0001–0086, Flutter `lib/`, Next.js `webapp/`). 10/10 sprint: kontrast, joylashuv, i18n, a11y, filter, chat, CORS, rate-limit.

---

## 1. Qisqa xulosa

Yollla — O‘zbekiston blue-collar bozori uchun jiddiy, production-ga yaqin mahsulot. Bitta Postgres, ikki xil UI (mobil auth-first, web auth-last), token-driven dizayn tizimi, RLS + definer RPC, SEO landing, admin panel — bular kam uchraydigan darajadagi poydevor.

**Lekin bu hali “millionlab odam kirsa ham turadi” degani emas.** Bugungi holat: 10–50 ming faol foydalanuvchiga yetadi; millionga — qidiruv, realtime, bildirishnomalar va to‘lov perimetri yiqiladi.

| Qatlam | Ball /10 | Holat |
|---|---:|---|
| Umumiy mahsulot | **7.3** | Kuchli poydevor, bir nechta yadro oqimlar hali “demo hidli” |
| Android UX | **7.6** | Map-first, App Links, FCM kanal — yaxshi; a11y va 5-tab zich |
| iOS UX | **7.1** | Ruxsat matnlari lokalizatsiya qilingan; Dynamic Type, landscape, ba’zi usage stringlar |
| Web (izlovchi) | **8.1** | Eng yaxshi sirt: SEO, auth-last, ISR, xarita |
| Web (ish beruvchi) | **7.4** | Guest post, Hamyon, pipeline — kuchli; form og‘ir |
| Mobil (izlovchi) | **7.5** | Apply/CV tuzatilgan; joylashuv fake, onboarding uzun |
| Mobil (ish beruvchi) | **6.8** | Dashboard/pipeline bor; inglizcha qoldiqlar, Hamyon ko‘milgan |
| Admin panel | **6.6** | Moderatsiya + moliya ishlaydi; rollar yo‘q, blog/mahsulot “tez kunda” |
| Dizayn tizimi | **6.9** | Tokenlar bor, lekin mobil ≠ web; volt kontrast |
| Arxitektura | **8.0** | Feature-first, `job_feed` shartnomasi, ikki shell |
| Xavfsizlik | **7.6** | 0027/0069/0073 P0 larni yopgan; scale-abuse ochiq |
| Scale (1M+) | **4.4** | Indekslar boshlangan; qidiruv/notify/realtime yetmaydi |

**Verdict:** Store va Vercel’ga chiqish mumkin (go-live — ops). Million foydalanuvchi — alohida infratuzilma dasturi. Avval brand birligi, kontrast, o‘lik/inglizcha UI, keyin qidiruv + notify scale.

---

## 2. Brand va dizayn tizimi

### 2.1 Nomlar chalkash — foydalanuvchi ishonchini yeydi

| Qayerda | Nima yozilgan |
|---|---|
| Store / manifest / iOS display | **Yollla** |
| Kod, widget, CLAUDE.md | **Yolla** |
| Package, bundle, deep link | **`io.jobzone.jobzone`** |
| Eski README | Jobzone + indigo `#3A36DB` |

Logo “yo” + “yolla” (bitta L), footer “Yollla”, ba’zi email/copy “Yolla”. Bu kichik ko‘rinadi, lekin App Store review, SEO knowledge panel va ishonch uchun **bitta yozuv** kerak. Tavsiya: tashqi olamda faqat **Yollla**, ichki identifikatorlar (`jobzone`) o‘zgarmasin.

### 2.2 Ikki xil “primary” — platformalar boshqa mahsulotdek

**Mobil (`JzColors`):**
- Primary = siyoh `#0A0A0A` (tugmalar qora)
- Accent/gold = volt `#C7FB00`
- Yaxshi: volt faqat badge, filter, xarita pin

**Web (`globals.css`):**
- `--primary: #c7fb00` — CTA **va** `text-primary` havolalar
- Volt oq fonda matn sifatida ≈ **1.3–1.5:1** — WCAG AA (4.5:1) dan ancha past

Natija: mobil — qora tugma + sariq nuqta; web — limon tugma + limon “Barchasi” havolasi. Bir brend, ikki til.

**Tuzatish:** web’da `--primary` ni ink qiling, voltni `--accent` / CTA-only token qoldiring. `text-primary` hech qachon volt bo‘lmasin.

### 2.3 Tipografika — rus tili ikkinchi navbatda

Archivo — Latin-only. `app_typography.dart` va web layout ochiq yozadi: ru Cyrillic **system fallback**.

Oqibat:
- O‘zbek/ingliz — Archivo, zich, brand
- Rus — aralash: lotin so‘zlar Archivo, kirill tizim shrifti
- Narxlar Space Mono (web) — kirill yo‘q

Blue-collar auditoriyaning katta qismi rus tilida. Bu “i18n bor” emas, **vizual ikkinchi navbat**.

### 2.4 Token intizomi

Yaxshi: `JzColors`, `AppSpacing`, `AppRadius`, light/dark, web CSS variables, `prefers-reduced-motion`.

Yomon:
- `Colors.black.withValues(alpha: 0.05)` soyalar — dark mode’da deyarli ko‘rinmaydi
- `withOpacity` (deprecated) employer dashboard’da
- Shadow token yo‘q
- Success/warning badge 12% tint ustida yashil/sariq matn — kontrast ~2–3:1
- Xarita pin ranglari (`#1F8F4E`) token emas

### 2.5 Harakat va ovoz

Web: `wizfade`, `successPop`, `tapPop`, toast, sound. Mobil: `JzFadeSlideIn`, `JzPulse`, `JzCountUp`. Bu mahsulotni “tirik” qiladi. Lekin employer dashboard’dagi count-up + inglizcha “Hiring Conversion Rate” — brand ohangini buzadi.

---

## 3. Android

### 3.1 Nima yaxshi

- `android:label="Yollla"`, `allowBackup="false"` — to‘g‘ri
- App Links: `yollla.uz` / `www.yollla.uz` + `/jobs|/companies|/ish|/resumes`
- OAuth: `io.jobzone.jobzone://login-callback`
- FCM: alohida high-importance kanal + monochrome `ic_stat_notify` (launcher ikonkasi oq kvadrat bo‘lmaydi)
- `queries` — https/http/tel/mailto (Android 11+ silent no-op oldini oladi)
- `windowSoftInputMode=adjustResize` — formalar klaviatura ostida qolmaydi
- `configChanges` ichida `fontScale` — tizim shrifti o‘zgarsa qayta start bo‘lmaydi

### 3.2 UX muammolari

**5 ta pastki tab.** Izlovchi: Bosh / Qidiruv / Saqlangan / Chat / Profil. Ish beruvchi: Dashboard / Vakansiyalar / Nomzodlar / Chat / Kompaniya. Material 3 da 5 label kichik telefon + katta shriftda kesiladi. Hamyon, bildirishnoma, filter — tabda yo‘q, ko‘milgan.

**Home header.** Qora “quloqchin” + oq qidiruv. Kuchli. Lekin:
- Joylashuv `homeLocationDefault` — har doim Toshkent, chevron olib tashlangan (yaxshi — yolg‘on affordance yo‘q), lekin foydalanuvchi o‘z shahrini ko‘rmaydi
- Qidiruv maydoni yozilmaydi — faqat Search sahifasiga push
- Filter alohida sariq kvadrat — yaxshi, lekin faol filter badge yo‘q
- Bildirishnoma — 9px qizil nuqta, son yo‘q

**Xarita preview.** 200px, `IgnorePointer`, tap → Explore. Aqlli. Lekin Yandex SDK og‘ir: Home ListView ichida xarita + keyin Explore’da yana — xotira/GPU past Android’da titraydi.

**Tizim Back.** `JzTopBar` ba’zi `go()` sahifalarida back ko‘rsatadi, `canPop()==false` bo‘lsa o‘lik. Apply → success stack muammosi qisman tuzatilgan, lekin pattern takrorlanadi.

**Ruxsatlar.** Location + notifications onboarding’da. Fine location blue-collar uchun mantiqiy, lekin “skip / keyinroq” zaif bo‘lsa, Play “not essential” rad etishi mumkin. `play-data-safety.md` bor — yaxshi.

**Dark mode.** Header `colors.primary` dark’da qog‘oz-oq bo‘ladi — home header birdan oq “shapka”. Light’da siyoh, dark’da teskari — kutilmagan.

### 3.3 Android prioritetlari

1. Home header dark’da ham siyoh qolsin (brand ink, theme primary emas)
2. Joylashuvni profil/GPS’dan o‘qish
3. Tab label `alwaysShow` + textScaler clamp 1.3
4. Xarita preview’ni past RAM’da statik rasmga almashtirish
5. Notification badge’da son

---

## 4. iOS

### 4.1 Nima yaxshi

- `CFBundleDisplayName = Yollla`
- `uz/ru/en` InfoPlist.strings — location va photo **o‘zbekcha** (mahsulot tili)
- `ITSAppUsesNonExemptEncryption = false` — TestFlight click-through yo‘q
- `UIBackgroundModes = remote-notification`
- Universal Links (`.well-known/apple-app-site-association`)
- PrivacyInfo.xcprivacy
- Portrait + landscape (iPhone)

### 4.2 UX / App Store risklari

**Permission stringlar Info.plist’da inglizcha fallback.** Agar lokalizatsiya yuklanmasa, “Yollla uses your location…” chiqadi. Review uchun OK, lekin `NSCameraUsageDescription` yo‘q — agar ImagePicker kamera yo‘lini ochsa, crash + review reject.

**Dynamic Type.** Hech qayerda `textScaler` clamp yo‘q. Home carousel `height: 220`, category chips `height: 40`, employer stat `mainAxisExtent: 80`. iOS Accessibility 200% da sariq-qora overflow. Blue-collar auditoriya katta shrift ishlatadi.

**Safe area.** Gallery viewer caption home indicator ostida qolishi mumkin. Web `env(safe-area-inset-bottom)` bor; mobil ba’zi full-screen sirtlarda yo‘q.

**Landscape iPhone.** Vakansiya kartasi + apply bar landscape’da buziladi. Ish ilovasi odatda portrait-only.

**Haptic / swipe.** Chat’da swipe-to-reply, home’da swipe-to-archive yo‘q. iOS foydalanuvchisi buni kutadi.

**CallKit / Agora.** Call UI scaffold; haqiqiy CallKit integration yo‘q — fon/lock screen chaqiruv iOS’da “soxta” tuyuladi.

### 4.3 iOS prioritetlari

1. Portrait-only iPhone
2. Camera usage string (yoki kamerani o‘chirish)
3. Text scale clamp + moslashuvchan kartalar
4. Full-screen SafeArea
5. CallKit yoki call tugmalarini yashirish

---

## 5. Web ilova

### 5.1 Eng kuchli qarorlar

**Auth-last.** Mehmon vakansiyani ko‘radi, CV to‘ldiradi, apply/post yozadi — login faqat oxirgi bosqichda, `sessionStorage` saqlaydi. Mobil auth-first. Bu **to‘g‘ri platforma farqi**.

**SEO mashinasi.** `/ish/[category]/[city]`, `/hudud/[region]`, sitemap, hreflang, FAQ JSON-LD, OG image, `revalidate = 300` + `revalidateTag("jobs")`. Yangi e’lon 5 daqiqadan oldin ham tag orqali chiqadi.

**Landing.** Qorong‘i xarita-poster hero, animatsiyali placeholder, shahar select, tirik xarita, kategoriya (faqat count>0), popular searches, recent, kompaniyalar, FAQ, employer CTA. Bo‘sh kategoriya yashirilgan — Day-1 “0 vakansiya” ishonchni o‘ldirmaydi.

**Mobil web.** Pastki tab bar + `--tabbar` token. Native ilova hissi.

**Dark mode.** `#181817` / `#e9e9e4` — to‘liq qora emas, o‘qish uchun ongli. Yaxshi yozilgan izoh.

### 5.2 Web UX muammolari

| Muammo | Og‘irlik | Nima bo‘ladi |
|---|---|---|
| Volt matn oqda (`text-primary`) | P0 a11y | “Barchasi” havolasi deyarli o‘qilmaydi |
| Archivo + ru fallback | P1 | Rus UI “yamalgan” |
| Landing xarita `cityLabel: "TOSHKENT"` hardcode | P1 | Boshqa shahar foydalanuvchisi |
| Guest post form juda uzun | P1 | Blue-collar HR tashlab ketadi |
| Account vs native tab IA | P2 | Web’da xabarlar `/account/messages` ichida |
| Admin sidebar mobilida gorizontal scroll | P2 | 14+ bo‘lim, barmoqqa sig‘maydi |
| Products / Blog “Tez kunda” | P3 | Admin nav’da o‘lik punktlar |
| `text-primary` hover underline | P2 | Volt chiziq ham zaif |

### 5.3 Web izlovchi oqimi

```
Landing → qidiruv/xarita/kategoriya → /jobs/[id] → apply (mehmon to‘ldiradi)
  → sign-in?next=… → restore → yuborildi
```

Bu HH.uz / OLX dan yaxshiroq conversion hunari. Xavf: apply form + auth orasida ishonch; screening savollar yo‘qolmasligi kerak (stash bor — saqlansin).

### 5.4 Web ish beruvchi oqimi

```
/employer (public landing) → /employer/jobs/new (guest) → auth → kompaniya
  → to‘lov (tier) → job_feed’da darhol
```

Kuchli. Zaif: paid/promote/share alohida sahifalar (`/pay`, `/paid`, `/promote`, `/share`) — xarita chalkash. Wizard yaxshi (`wizfade`), lekin 25+ maydon blue-collar HR uchun ko‘p. “3 maydon + keyin boyitish” yaxshiroq.

---

## 6. Ish izlovchi tomoni

### 6.1 Asosiy sayohat (mobil)

| Qadam | Holat | Izoh |
|---|---|---|
| Til | Yaxshi | Birinchi ekran, uz default |
| Onboarding 3 slayd | O‘rtacha | Illustratsiya bor; blue-collar uchun qisqaroq bo‘lishi mumkin |
| Auth | Yaxshi | Email, Google, Telegram OTP |
| Rol tanlash | Yaxshi | Bir marta, qaytarib bo‘lmaydi |
| Complete profile | Zaif | Gender saqlanmasligi mumkin; telefon hint i18n |
| Preferences 4 qadam | Zaif | Bo‘sh o‘tish mumkin; matching o‘chadi |
| Location + push ruxsati | O‘rtacha | Skip yo‘li noaniq |
| Home | Yaxshi | Xarita + kategoriya + recommended + recent |
| Qidiruv / filter | Yaxshi* | UZS 0–30 mln, live “N vakansiya”; sort/inclusion endi bor-yo‘qligini UI’da tekshirish kerak |
| Vakansiya | Yaxshi | About / Company / Reviews |
| Apply | **Tuzatilgan** | CV yuklanadi, saqlangan rezyume preselect, cover/screening validatsiya |
| Mening arizalarim | O‘rtacha | Timeline ba’zan bo‘sh; yopilgan ishlar endi saqlanishi kerak (0048) |
| CV tahrir | Yaxshi | 10+ bo‘lim; sana oralig‘i validatsiyasi zaif |
| Chat | O‘rtacha | Realtime bor; attach/mic “tez kunda”; online nuqta soxta |
| Hisob | O‘rtacha | Delete account **endi ishlaydi** (edge fn) |

### 6.2 Izlovchi UX prinsip holati

**Nima ishlaydi**
- Bir tap apply (web + mobil)
- Recommended jobs (rezyume matching)
- Saqlangan qidiruv + alert
- Arxiv (dismiss)
- Trust badge (telefon/worker verified)
- 3 til, parity test

**Nima ishonchni yeydi**
- Home joylashuvi doim Toshkent
- “Online” yolg‘on
- Composer +/mic o‘lik, lekin UI va’da qiladi
- Help Center qidiruvi/chiplari o‘lik bo‘lishi mumkin
- Ikki xil profil % (8 vs 10 mezon)
- Ish haqi “so'm” / “/month” ba’zi joylarda hali lotin-en

### 6.3 Blue-collar maxsus

Bu auditoriya:
- Kichik ekran, sekin internet, katta shrift
- PDF CV emas — telefon + “hozir ishlayman”
- Ayollar/nogironlar filtrlari — mahsulot farqi

Shuning uchun: **worker card + one-tap + xarita** to‘g‘ri. Uzun CV wizard (volunteer, awards, projects) oq yoqa. Default yo‘l: 4 maydon (ism, tel, kategoriya, shahar) + ixtiyoriy CV.

---

## 7. Ish beruvchi tomoni

### 7.1 Mobil — Yolla Business

5 tab: Dashboard · Vakansiyalar · Nomzodlar · Chat · Kompaniya.

**Dashboard**
- 4 stat + oxirgi 5 nomzod + retry — yaxshi
- **P1:** “Hiring Conversion Rate” / “% of applicants reached interview” — qattiq inglizcha, uz/ru UI ichida
- RefreshIndicator `invalidate` qiladi, `await` qilmaydi — spinner miltillaydi
- Kompaniya yo‘qida sarlavha “Dashboard”
- Stat qator 80px — katta shriftda siqiladi

**Vakansiya joylash**
- Blue-collar maydonlar: 6/1, tungi smena, ayollar/nogironlar, haydovchilik, screening, markdown, OSM, schedule — **bozor darajasi**
- Forma ~25 maydon, PopScope yo‘q — back hammasi yo‘qoladi
- AI generate tasdiqsiz ustiga yozishi mumkin
- min > max maosh o‘tishi mumkin

**Nomzodlar**
- Pipeline, xarita, masofa — farq qiladigan xususiyat
- Status tanlashda barcha 7 holat ochiq, rejected/hired tasdiqsiz
- Timeline live rejimda bo‘sh qolgan joylar bo‘lishi mumkin

**Hamyon / promo**
- Payme/Click/Rahmat kodi bor
- Tabda yo‘q — Kompaniya yoki checkout orqali
- Featured vs TOP farqi UI’da zaif bo‘lsa, arzon paketni olishadi

**Rol qulfi.** Bir akkaunt = bir rol. To‘g‘ri (RLS soddalashadi), lekin “men ham izlayman, ham yollayman” — O‘zbekistonda odatiy. Ikkinchi akkaunt majburiy. Web’da RoleToggle boshqacha tuyuladi.

### 7.2 Web employer

Onboarding kompaniya yaratadi va `profiles.role` ni employer qiladi. Guest post + auth-last. Applicants, matches, paid, promote, share, wallet.

**UX tirqish:** `/employer` public landing va signed-in dashboard **bir URL**. Aqlli, lekin bookmark/back chalkash.

---

## 8. Admin panel

### 8.1 Axborot arxitekturasi

```
Overview     Dashboard
Moderatsiya  Users · Companies · Jobs · Reviews · Reports
Kontent      Categories · Telegram kanallar · [Products] · [Blog]
Moliya       Hamyon · Buyurtmalar
Tizim        Broadcast · Settings · Audit
```

Bu to‘g‘ri. Moderatsiya + pul + audit — marketplace adminning yadrosi.

### 8.2 Nima yaxshi

- `requireAdmin()` har sahifada + layout; noadmin = **404** (panel ko‘rinmaydi)
- `is_admin()` JWT `app_metadata.role` — client o‘zini admin qila olmaydi
- Yozuvlar definer RPC + `admin_audit()`
- `robots: noindex`, `dynamic = "force-dynamic"`
- Dashboard: seeker/employer, ochiq ishlar, voronka, top kategoriya/shahar, daromad, wallet liability
- Sidebar siyoh + volt active — brand

### 8.3 Admin UX tirqishlari

| Muammo | Nima uchun muhim |
|---|---|
| Faqat bitta admin roli | Moderator vakansiyani yopsin, lekin Hamyon’ga tegmasin — hozir hammasi yoki hech narsa |
| 2FA / step-up yo‘q | Admin JWT o‘g‘irlansa — butun platforma |
| Strings hardcode o‘zbekcha | `admin/page.tsx` — next-intl emas; ru/en admin yo‘q |
| Mobil nav gorizontal | 15 item, “Tez kunda” ham joy oladi |
| Products/Blog disabled | O‘lik IA |
| Service role yo‘q = degraded | `ReadKeyMissing` — admin “bo‘sh” ko‘rinadi, tushuntirish zaif |
| Dashboard “hodisalar jurnali yo‘q” | O‘zlari yozgan — DAU/WAU yo‘q, faqat created_at |
| Broadcast | Millionga bitta INSERT × N notify — xavfli tugma |

Admin **operatsion** panel, marketing CMS emas. Blogni yashirish — to‘g‘ri. Yetishmaydi: navbat (moderation queue), SLA, “bugun nima qilish kerak” inbox.

---

## 9. Arxitektura

### 9.1 Umumiy rasm

```
                    ┌──────────── webapp (Next 16) ────────────┐
  Guest SEO  ──────►│ RSC + job_feed + ISR                     │
  Auth-last  ──────►│ Server Actions · proxy.ts · /admin       │
                    └──────────────────┬───────────────────────┘
                                       │ anon / user JWT
  Flutter iOS/Android                  ▼
  auth-first shells ──────────►  Supabase  (Auth · Postgres+RLS · Storage · Realtime)
  seeker | employer                    │
                                       ├── Edge Functions (notify, pay, OTP, AI…)
                                       ├── pg_cron (publish + alerts)
                                       └── Meili (legacy, live yo‘l emas)
```

**Invariantlar (saqlansin):**
1. Bitta DB, ikki UI — ekranlarni ko‘chirmaslik
2. Mobil auth-first, web auth-last
3. Post → darhol `job_feed` da ikkala client
4. Demo data yo‘q
5. Client o‘ziga ruxsat bera olmaydi

Bu arxitektura to‘g‘ri.

### 9.2 Mobil tuzilish

```
lib/
  app/            router (2 StatefulShellRoute + guards)
  core/           env, supabase, storage
  design_system/  tokens + Jz* widgets
  features/*/     data · domain · presentation
  localization/   uz/ru/en ARB
  shared/         enums = DB wire
```

Riverpod qo‘lda, codegen yo‘q — o‘qiladi. Guard `resolveRedirect` sof funksiya, testlangan. Employer chat endi `inShared` orqali ochiladi. Password reset `newPassword` exception.

**Zaiflik:** `appFlags` (local) vs `profiles.role` (server). Guard local flag’ga ishonadi. RLS haqiqiy panjara, lekin UI chalg‘itishi mumkin.

### 9.3 Web tuzilish

```
webapp/src/
  app/[locale]/   pages (uz default)
  components/     ui · jobs · employer · admin · landing
  lib/data/       server-only readers (status=open majburiy)
  lib/actions/    mutations
  proxy.ts        optimistic gate, fail-open
```

`getCurrentUser()` cookies() ni yutadi → `force-dynamic` unutilsa, bitta logged-out HTML hammaga ketadi. Bu hujjatlangan tuzoq — har yangi gated sahifada takrorlanadi.

### 9.4 Backend tuzilish

86 migratsiya, 20+ edge function. `job_feed` — yagona o‘qish shartnomasi. Pul: client amount’ga ishonmaslik, `gateway_settle_order`. Boost/verification — BEFORE trigger + definer RPC.

**Qarz:**
- Meili kodda qolgan, live qidiruv — Postgres `ILIKE` + `pg_trgm`
- Mock repo production binary’da (faqat test, lekin hajm)
- Migratsiya dublikat versiya 3 marta “silent skip” qilgan — endi `check-migrations.sh` bor

---

## 10. Xavfsizlik (joriy holat)

### 10.1 Yopilgan (eski P0)

| Avval | Hozir |
|---|---|
| `profiles` SELECT hammaga, lat/lng/pay/tel | 0027: owner-only; `profiles_public` xavfsiz ustunlar |
| `contact_info` dunyoga ochiq | 0027: owner-only |
| Applicant o‘zini `hired` qilardi | 0027 + 0073 clamp INSERT `submitted` |
| Istalgan chatga self-join | 0027: insert olib tashlangan |
| Edge secret fail-open | `_shared/auth.ts` fail-closed + constant-time |
| Telegram webhook soxta update | `requireTelegramSecret` |
| Delete account “coming soon” | `delete-account` fn + UI |
| Company `owner_id` unique yo‘qligi | keyingi migratsiyalarda qisman |

Bu jiddiy muhandislik. Eski `audit-findings.md` ni “hammasi ochiq” deb o‘qimang.

### 10.2 Qolgan xavflar

**P1 — moliyaviy / abuse**
- Rate limit **in-memory Map**, bitta isolate. Edge cold start / ko‘p instance = limit yo‘q. `search-jobs` 120/min/IP — scraping uchun yetarli.
- `checkRateLimit` deyarli faqat search-jobs’da. `generate-job-content`, `parse-resume`, payment — bill/DoS.
- CORS `*` hali bor.
- Admin bitta claim, 2FA yo‘q.
- Payment webhook imzo tekshiruvi gateway-specific — secret rotatsiya runbooki zaif.

**P1 — PII**
- `job_feed` `j.*` orqali `contact_phone` `show_phone_on_listing=false` bo‘lsa ham ketishi mumkin (eski topilma — view qayta yozilganmi, tekshirish kerak).
- Resume storage: employer signed URL yo‘li 0047 da boshlangan — muddat/audit?
- Exact GPS endi faqat `applicant_locations` (job owner) — yaxshi. Public view’da yo‘q.

**P2**
- Router local flags
- Change-password old password’siz (Supabase `updateUser`)
- Chat ID UUID + notification payload
- Skills katalogi spam (agar insert ochiq qolgan bo‘lsa)

**P2 — ops**
- `SERVICE_ROLE` webapp’da admin o‘qish uchun. Leak = to‘liq DB.
- Go-live checklistdagi secretlar qo‘yilmasa, funksiyalar 503 (fail-closed) — to‘g‘ri, lekin OTP “ishlamaydi” deb ko‘rinadi.

### 10.3 Privacy / store

- `allowBackup=false`
- `play-data-safety.md`, `privacy-policy.html`
- Account deletion bor — GDPR/Play talab
- iOS usage stringlar lokal

---

## 11. Millionlab odam kirsa nima bo‘ladi?

Ssenariy: 1 000 000 ro‘yxatdan o‘tgan, 80 000 DAU, 15 000 bir vaqtda, 50 000 ochiq vakansiya, 200 000 ariza/kun, chat + push yoqilgan.

### 11.1 Birinchi 15 daqiqa — nima sinadi

**1. Postgres ulanishlari (birinchi o‘lim)**  
Har mobil ochilishi: Auth + `job_feed` + categories + notifications + bookmarks. Web ISR landing’ni saqlaydi, lekin `/jobs` va apply — to‘g‘ridan-to‘g‘ri. Supabase direct 5432 session mode ~60–200 ulanish. Spike’da:

```
remaining connection slots reserved for superuser
```

Ilova: skeleton abadiy yoki `errUnknown`.  
**Kerak:** Transaction pooler (6543), server-side faqat pooler, mobil so‘rovlarni birlashtirish.

**2. `job_feed` + RLS**  
Har qator: `status=open` + owner exception + company join + boost hisoblash. 50k ochiq × 15k concurrent = seq scan + RLS CPU. 0081/0086 indekslar yordam beradi **toki** filter `posted_at` + city. `ILIKE '%term%'` trigram bilan ham og‘ir.

**3. Qidiruv**  
Live yo‘l — Postgres, Meili emas. 80k odam “haydovchi Toshkent” deb yozsa:

- Har keystroke count (mobil filter 350ms debounce) = HEAD so‘rovlar
- Trigram yordam beradi, lekin ranking yo‘q, typo yo‘q, geo-sort zaif

Natija: 2–8 soniya, timeout, bo‘sh ro‘yxat.  
**Kerak:** Meili yoki Typesense ni **qayta asosiy** qilish (hozir legacy). Structured filter server-side.

**4. Bildirishnomalar**  
`INSERT notifications` → trigger → `pg_net` → `notify-dispatch` → Telegram + FCM + email. 200k ariza/kun, har status o‘zgarishi, saved-search cron:

- `pg_net` navbati to‘ladi
- Edge fan-out timeout
- Resend/Telegram rate limit
- FCM “unavailable”

Broadcast tugmasi admin’dan 1M qator yozsa — **o‘z-o‘zini DoS**.

**5. Realtime chat**  
Har ochilgan suhbat — websocket. `messagesProvider` avval leak qilgan; autoDispose bo‘lsa ham 10k parallel kanal Supabase Realtime limitidan oshadi. Xabar kechikadi yoki ulanish uziladi.

**6. Edge in-memory rate limit**  
100+ isolate × 120 req = deyarli cheksiz scraping. Vakansiya + tel raqamlar.

**7. Storage / xarita**  
Yandex SDK + OSM tile + avatar CDN. Tile kvotasi, MapKit key, image transform yo‘q — traffic hisobi.

**8. Auth / OTP**  
Telegram Gateway + email confirm. Viral spike’da hook 429, foydalanuvchi “kod kelmadi”.

### 11.2 Nima tura oladi

| Qism | Nega |
|---|---|
| Web landing / `/ish/*` | ISR + CDN, 300s, tag flush |
| Statik assetlar | Vercel / store CDN |
| RLS to‘g‘riligi | Trafik oshsa ham izolyatsiya ishlaydi |
| To‘lov settle | `gateway_settle_order` bitta yo‘l |
| Indekslar 0081/0086 | 100k qatorgacha feed OK |

### 11.3 Scale dasturi (bosqichma-bosqich)

**A. 100k foydalanuvchi (majburiy hozir)**
1. Barcha backend — PgBouncer transaction mode
2. `job_feed` o‘rniga materialized yoki `jobs_open` jadvalli projection
3. Qidiruvni Meili/Typesense ga qaytarish, filter whitelist serverda
4. Rate limit — Redis/Upstash, barcha edge
5. Notify — navbat (pgqueue / SQS), trigger ichida HTTP yo‘q
6. Broadcast — batch + throttle, hech qachon 1M sync insert
7. Realtime faqat ochiq chat, qolgani poll
8. Read replica — feed/search

**B. 1M foydalanuvchi**
1. Multi-region read (Toshkent + Frankfurt)
2. Image CDN + resize (avatars 64/128/256)
3. Push: topic + collapse key, har eventga shaxsiy HTTP yo‘q
4. Chat: alohida xizmat (LiveKit/Supabase alohida project) yoki kunduzgi digest
5. Observability: p95 latency, RLS time, queue depth, error budget
6. Feature flag + load-shed (xarita o‘chadi, list qoladi)
7. Legal: spam, firibgar ish, bolalar mehnati — trust & safety jamoa

**C. Nima qilmaslik**
- “Supabase o‘zi scale qiladi” deb o‘tirish
- Meili’ni o‘chirib, ILIKE’da millionga chiqish
- Har notify’da 3 kanal sinxron
- Admin broadcast’ni cheklovsiz qoldirish

### 11.4 Taxminiy sig‘im (bugungi kod)

| Metrika | Qulay | Og‘riq | Sindirish |
|---|---:|---:|---:|
| Ro‘yxatdan o‘tgan | 50k | 200k | 1M+ |
| DAU | 5–8k | 25k | 80k |
| Ochiq vakansiya | 5k | 30k | 100k |
| Bir vaqtda | 500 | 3k | 15k |
| Realtime kanal | 200 | 1k | 5k+ |

Bu taxmin — load test yo‘q. Birinchi ish: k6/Gatling `job_feed` + search + apply.

---

## 12. Platformalar kesishmasi

| Oqim | Android | iOS | Web |
|---|---|---|---|
| Birinchi ochilish | Auth-first, til, onboarding | Xuddi + ruxsat dialog | SEO landing, auth yo‘q |
| Qidiruv | In-app, xarita tab | Xuddi, Yandex | URL facet, SEO landings |
| Apply | Session shart | Session shart | Mehmon → login |
| Chat | Native, push | Native, APNs | Account ichida |
| To‘lov | WebView gateway | WebView (IAP emas — yaxshi) | Redirect |
| Admin | Yo‘q | Yo‘q | `/admin` |
| Xarita | Yandex SDK | Yandex SDK | OSM/Leaflet |

**Yaxshi:** web ≠ mobil klon.  
**Yomon:** primary rang, tipografika, “Yolla/Yollla”, home joylashuvi.

To‘lov IAP emas — App Store 30% va “digital goods” tortishuvidan qochilgan. Vakansiya e’loni real-world service — odatda ruxsat. Legal review baribir kerak.

---

## 13. Top-20 — hozir tuzating

Tartib: ishonch / xavfsizlik / conversion, keyin scale.

| # | Sev | Qayerda | Ish |
|---|---|---|---|
| 1 | P0 | Web | Voltni matndan olib tashlash; CTA only |
| 2 | P0 | Brand | Yollla vs Yolla vs Jobzone — tashqi nom bitta |
| 3 | P0 | Scale | Notify’ni navbatga olish; broadcast throttle |
| 4 | P0 | Scale | Qidiruvni Meili/Typesense + server filter |
| 5 | P0 | Infra | PgBouncer + connection budget |
| 6 | P1 | Mobil | Home joylashuvi haqiqiy shahar |
| 7 | P1 | Employer | “Hiring Conversion Rate” ni l10n yoki olib tashlash |
| 8 | P1 | Chat | Soxta Online / o‘lik + va mic — yashirish yoki qilish |
| 9 | P1 | Tipografika | Ru uchun Cyrillic yuz (onboard font) |
| 10 | P1 | A11y | textScaler clamp, 48dp, Semantics `JzCircleButton` |
| 11 | P1 | Employer | Post-job PopScope + maosh min≤max |
| 12 | P1 | Admin | Moderator vs finance rollari + 2FA |
| 13 | P1 | Rate limit | Upstash, barcha edge |
| 14 | P1 | Dark home | Header doim ink |
| 15 | P1 | iOS | Portrait-only, camera string |
| 16 | P2 | Filter | Faol filter badge; sort UI |
| 17 | P2 | Profile | Bitta completion metriki |
| 18 | P2 | Help | O‘lik qidiruv/chiplarni ulash yoki olib tashlash |
| 19 | P2 | CORS | `*` ni yopish |
| 20 | P2 | Observability | p95, queue, crash-free; Firebase init xatosini log |

---

## 14. Sahifa/modul ballari

### Mobil izlovchi

| Ekran | UX | Izoh |
|---|---:|---|
| Splash / til | 8 | Aniq |
| Onboarding | 7 | Biroz uzun |
| Auth | 8 | OTP + Google |
| Home | 7.5 | Xarita yaxshi, joylashuv yolg‘on |
| Explore/xarita | 7.5 | Cluster, near-me kosmetik bo‘lishi mumkin |
| Filter | 8 | UZS live count |
| Job details | 8 | Tablar aniq |
| Apply | 8 | CV endi ketadi |
| CV | 7 | Oq yoqa og‘ir |
| Chat | 6 | Soxta presence, stub composer |
| Notifications | 7 | Deep-link tekshirish |
| Settings | 7.5 | Delete ishlaydi |

### Mobil ish beruvchi

| Ekran | UX | Izoh |
|---|---:|---|
| Dashboard | 6 | Inglizcha blok, refresh |
| Post job | 7 | Kuchli maydonlar, og‘ir forma |
| My jobs | 7 | |
| Applicants | 7.5 | Xarita farq qiladi |
| Wallet | 6.5 | Ko‘milgan |
| Company admin | 6.5 | URL-paste vs picker |

### Web

| Sirt | UX | Izoh |
|---|---:|---|
| Landing | 8.5 | Eng yaxshi ekran |
| /jobs, /ish/* | 8 | SEO + facet |
| Job page | 8 | OG, apply |
| Resume wizard | 8 | Auth-last |
| Employer post | 7 | Uzun |
| Account | 7 | |
| Admin | 6.5 | Funksional, xom |

---

## 15. Yakuniy baho

Yollla **qobiliyatli jamoa mahsuloti**: xavfsizlik auditidan keyin haqiqiy lock-down qilingan, izlovchi web conversion hunari zamonaviy, blue-collar maydonlar (smena, rasmiylashtirish, xarita) bozorni tushunadi.

U **hali** quyidagilar emas:
- bir xil brend tizimi (rang + nom + shrift)
- iOS/Android accessibility jihatdan barqaror
- admin sifatida trust & safety operatsiyasi
- million foydalanuvchilik arxitektura

**Chiqish strategiyasi**
1. **Hozir (2 hafta):** kontrast, nom, inglizcha qoldiq, o‘lik tugmalar, portrait, header ink. Store + yollla.uz.
2. **Keyin (1 oy):** Meili qidiruv, notify navbati, pooler, rate limit, load test.
3. **O‘sish:** rollar, 2FA admin, read replica, image CDN, chat ajratish.

Million odam kirsa **bugun:** landing ochiladi, login/qidiruv/chat/push sekinlashadi yoki yiqiladi, admin broadcast platformani o‘zi uradi. Ma’lumot odatda oqmasligi kerak (RLS 0027+). UX oqadi.

---

*Bu audit implementatsiya emas — holat xaritasi. Keyingi qadam: P0/P1 larni sprintlarga bo‘lish yoki bitta oqimni (masalan web kontrast + brand) hozir tuzatish.*
