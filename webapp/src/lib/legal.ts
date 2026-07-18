/**
 * Yollla legal-text content — Privacy Policy and Terms of Service.
 *
 * Stored as structured sections per locale so the pages that render them
 * (`/[locale]/privacy`, `/[locale]/terms`) can style them uniformly and the
 * copy is version-controlled next to the code that references it. This is a
 * REASONABLE INITIAL DRAFT — mandatory legal review by counsel before public
 * launch. Effective date + last-updated stamp travel with the content so
 * users see when it was last changed.
 *
 * Both documents disclose:
 * - What data Yollla collects and why (matches PrivacyInfo.xcprivacy)
 * - Who it's shared with (Supabase, Firebase, Yandex, Google, Meta, Sentry,
 *   PostHog — every third-party processor a live build actually touches)
 * - User rights (access, correction, deletion, portability)
 * - Contact + retention
 *
 * The three locale objects share the same section shape so each page renders
 * identically regardless of language. To add a new locale, add a fourth
 * object with the same `sections[].id` keys.
 */

export interface LegalSection {
  id: string;
  title: string;
  paragraphs: string[];
}

export interface LegalDocument {
  title: string;
  effectiveDate: string;
  intro: string;
  sections: LegalSection[];
  contactLead: string;
  contactEmail: string;
}

export type LegalLocale = "uz" | "ru" | "en";

// ISO date the current version of these documents took effect. Bump when the
// legal team publishes new text so returning users can see the change.
export const LEGAL_EFFECTIVE_DATE = "2026-07-16";

const SUPPORT_EMAIL = "support@yollla.uz";

// ────────────────────────────────────────────────────────────────────────────
// PRIVACY POLICY — uz (product default)
// ────────────────────────────────────────────────────────────────────────────
const privacyUz: LegalDocument = {
  title: "Maxfiylik siyosati",
  effectiveDate: LEGAL_EFFECTIVE_DATE,
  intro:
    "Yollla — O'zbekiston uchun mobil ish qidirish va yollash bozori. Ushbu siyosat qanday ma'lumot yig'ishimizni, nima uchun, kimga uzatishimizni va sizning tanlovlaringizni tushuntiradi.",
  sections: [
    {
      id: "collect",
      title: "1. Qanday ma'lumot yig'amiz",
      paragraphs: [
        "Hisob ma'lumotlari: elektron pochta, parol (auth provayder tomonidan xesh qilingan), telefon raqami — hisobingizni yaratish, xavfsizligini ta'minlash va kirish uchun.",
        "Profil va rezyume: ism, sarlavha, biografiya, rasm, ish tajribasi, ta'lim, ko'nikmalar, kutilgan maosh, mavjudlik, yuklangan rezyume fayllari, aloqa havolalari — profilingizni tuzish, ish beruvchilarga sizni baholash imkonini berish, ishlarga ariza topshirish uchun.",
        "Joylashuv: taxminiy yoki aniq koordinatalar (faqat siz ruxsat bergan yoki joylashuv o'rnatgan taqdirda) — yaqin ish o'rinlarini ko'rsatish va masofani hisoblash uchun.",
        "Arizalar: motivatsion maktublar, tekshiruv javoblari, biriktirilgan rezyume — ish beruvchilarga arizalaringizni yuborish uchun.",
        "Xabarlar: ish qidiruvchi va ish beruvchi o'rtasidagi chat mazmuni — ilova ichida yozishmalar uchun.",
        "Ish beruvchi ma'lumotlari: kompaniya nomi, profil, jamoa, ish e'lonlari — ish beruvchi tomonini boshqarish uchun.",
        "Qurilma va foydalanish: push bildirishnoma token, qurilma platformasi, xatcho'plar, qidiruvlar — bildirishnomalar yuborish va tasmani shaxsiylashtirish uchun.",
      ],
    },
    {
      id: "use",
      title: "2. Ma'lumotlaringizdan qanday foydalanamiz",
      paragraphs: [
        "Bozorni ishlatish: ish e'lon qilish, qidirish, ariza topshirish, arizachilarni boshqarish, chat.",
        "Ish qidiruvchi va ish o'rinlarini moslashtirish (ixtiyoriy \"yaxshi mos kelish\" AI baholash bilan).",
        "Siz yoqgan bildirishnomalarni yuborish (ilova ichida, push va — agar Telegramni ulasa — Telegram).",
        "Xizmatni xavfsiz tutish va suiiste'mollarning oldini olish.",
        "Biz shaxsiy ma'lumotlaringizni SOTMAYMIZ va uni uchinchi tomon reklamasi uchun ISHLATMAYMIZ.",
      ],
    },
    {
      id: "visibility",
      title: "3. Boshqa foydalanuvchilarga ko'rinishi",
      paragraphs: [
        "\"Ishga tayyor\" belgisini qo'ysangiz, ish beruvchilar sizning umumiy profil kartangizni topa oladi (ism, sarlavha, rasm, shahar, ko'nikmalar).",
        "Aniq uy koordinatalaringiz, telefon, email, biografiya va uy manzilingiz boshqa foydalanuvchilarga KO'RSATILMAYDI; ariza bergan aniq ish uchun aniq joylashuvingiz faqat o'sha ish beruvchi bilan ulashiladi.",
        "Ish beruvchining ish e'lonlari va kompaniya profillari ilova ichida ochiq.",
      ],
    },
    {
      id: "processors",
      title: "4. Xizmat provayderlar bilan ulashish",
      paragraphs: [
        "Xizmatimizni ishlatish uchun quyidagi ishonchli provayderlarga cheklangan ma'lumotni uzatamiz:",
        "Supabase — backend, auth, ma'lumotlar bazasi, fayl saqlash.",
        "Firebase Cloud Messaging (Google) — push bildirishnomalarni yetkazish.",
        "Yandex Maps — xarita, joylashuv va geokoderlash.",
        "Telegram Gateway — telefon tasdiqlash kodlari va bot orqali bildirishnomalar (agar ulagan bo'lsangiz).",
        "Sentry — xatolik va ish faoliyati monitoringi (PII yuborilmaydi).",
        "Vercel, Google Analytics 4, Yandex.Metrica, Meta Pixel, PostHog — anonim foydalanish tahlili (ko'rish, sahifa yuklanishi).",
        "Anthropic (Claude) — ixtiyoriy AI yordamchisi (rezyume tahlili, ish e'loni yozish).",
      ],
    },
    {
      id: "rights",
      title: "5. Sizning huquqlaringiz",
      paragraphs: [
        "Kirish: hisobingizdagi ma'lumotlarni ko'rish va tahrirlash — Profil sozlamalari orqali.",
        "Tuzatish: noto'g'ri ma'lumotlarni to'g'irlash — o'sha yerda.",
        "O'chirish: hisobingizni butunlay o'chirish — Sozlamalar → Hisobni o'chirish. Barcha shaxsiy ma'lumotlaringiz 30 kun ichida o'chiriladi (ba'zi xizmat jurnallari qonun bo'yicha uzoqroq saqlanadi).",
        "Portativlik: ma'lumotlaringizning nusxasini so'rash — quyidagi email orqali.",
        "Norozilik: ma'lumot yig'ishga norozilik bildirish — quyidagi email orqali.",
      ],
    },
    {
      id: "retention",
      title: "6. Saqlash muddati",
      paragraphs: [
        "Faol hisob: siz hisobni o'chirmaguncha ma'lumot saqlanadi.",
        "O'chirilgan hisob: shaxsiy ma'lumotlar 30 kun ichida o'chiriladi. Anonimlashtirilgan xizmat jurnallari (masalan, kim yollangani statistikasi) uzoqroq saqlanishi mumkin.",
        "Ariza va yozishmalar: hisob o'chirilganda ular ham o'chiriladi.",
        "To'lov: soliqqa oid yozuvlar O'zbekiston qonunlariga muvofiq saqlanadi.",
      ],
    },
    {
      id: "security",
      title: "7. Xavfsizlik",
      paragraphs: [
        "Barcha ma'lumotlar shifrlangan holda uzatiladi (HTTPS/TLS).",
        "Parollar bir tomonlama xesh qilinadi (hech qachon oshkora saqlanmaydi).",
        "Fayllar (rezyume, rasmlar) Supabase Storage'da RLS siyosatlari bilan himoyalangan.",
        "Xavfsizlik hodisasi yuz bersa, sizga darhol xabar beriladi.",
      ],
    },
    {
      id: "children",
      title: "8. Bolalar",
      paragraphs: [
        "Yollla 16 yoshdan katta foydalanuvchilar uchun mo'ljallangan. Agar biz bilmasdan 16 yoshdan kichik bolaning ma'lumotini yig'ib qo'ygan bo'lsak, uni darhol o'chirib tashlaymiz.",
      ],
    },
    {
      id: "changes",
      title: "9. Ushbu siyosatga o'zgartirishlar",
      paragraphs: [
        "Yollla bu siyosatni yangilashi mumkin. Muhim o'zgarishlar ilova va emailingizga xabar beriladi. Yangi versiya kuchga kirgan sanadan boshlab qo'llaniladi.",
      ],
    },
  ],
  contactLead: "Savollar bo'lsa yoki huquqlaringizni amalga oshirmoqchi bo'lsangiz, biz bilan bog'laning:",
  contactEmail: SUPPORT_EMAIL,
};

// ────────────────────────────────────────────────────────────────────────────
// PRIVACY POLICY — ru
// ────────────────────────────────────────────────────────────────────────────
const privacyRu: LegalDocument = {
  title: "Политика конфиденциальности",
  effectiveDate: LEGAL_EFFECTIVE_DATE,
  intro:
    "Yollla — мобильная площадка поиска работы и найма для Узбекистана. Эта политика объясняет, какие данные мы собираем, зачем, кому передаём и какие у вас есть возможности.",
  sections: [
    {
      id: "collect",
      title: "1. Какие данные мы собираем",
      paragraphs: [
        "Учётные данные: email, пароль (хешируется провайдером аутентификации), номер телефона — для создания и защиты аккаунта, входа.",
        "Профиль и резюме: имя, должность, био, фото, опыт работы, образование, навыки, желаемая зарплата, доступность, загруженные файлы резюме, контактные ссылки — для построения профиля и подачи откликов.",
        "Геолокация: приблизительные или точные координаты (только с вашего разрешения) — чтобы показывать вакансии рядом и рассчитывать расстояние.",
        "Отклики: сопроводительные письма, ответы на скрининг, вложенные резюме — для отправки откликов работодателям.",
        "Сообщения: содержимое чатов между соискателями и работодателями — для внутренней переписки.",
        "Данные работодателя: название компании, профиль, команда, вакансии — для работы стороны работодателя.",
        "Устройство и использование: токен push-уведомлений, платформа устройства, закладки, поиски — для доставки уведомлений и персонализации ленты.",
      ],
    },
    {
      id: "use",
      title: "2. Как мы используем ваши данные",
      paragraphs: [
        "Работа площадки: публикация вакансий, поиск, отклики, управление кандидатами, чат.",
        "Сопоставление соискателей и вакансий (с необязательной AI-оценкой «насколько подходит»).",
        "Отправка включённых вами уведомлений (в приложении, push и — если подключили — Telegram).",
        "Обеспечение безопасности сервиса и предотвращение злоупотреблений.",
        "Мы НЕ продаём ваши персональные данные и НЕ используем их для рекламы третьих сторон.",
      ],
    },
    {
      id: "visibility",
      title: "3. Что видят другие пользователи",
      paragraphs: [
        "Когда вы отмечаетесь «открыт к работе», работодатели могут найти вашу публичную карточку профиля (имя, должность, фото, город, навыки).",
        "Точные домашние координаты, телефон, email, био и адрес НЕ показываются другим пользователям; точная геолокация кандидата передаётся работодателю только по конкретной вакансии, на которую вы откликнулись.",
        "Вакансии работодателей и профили компаний публичны в приложении.",
      ],
    },
    {
      id: "processors",
      title: "4. Обработчики данных",
      paragraphs: [
        "Для работы сервиса мы передаём ограниченные данные проверенным провайдерам:",
        "Supabase — бэкенд, авторизация, база данных, файловое хранилище.",
        "Firebase Cloud Messaging (Google) — доставка push-уведомлений.",
        "Yandex Maps — карты, геолокация и геокодирование.",
        "Telegram Gateway — коды подтверждения телефона и уведомления через бота (если подключены).",
        "Sentry — мониторинг ошибок и производительности (PII не передаётся).",
        "Vercel, Google Analytics 4, Yandex.Metrica, Meta Pixel, PostHog — анонимная аналитика использования.",
        "Anthropic (Claude) — опциональный AI-ассистент (разбор резюме, черновики вакансий).",
      ],
    },
    {
      id: "rights",
      title: "5. Ваши права",
      paragraphs: [
        "Доступ: просмотр и редактирование данных аккаунта — через Настройки профиля.",
        "Исправление: корректировка неверных данных — там же.",
        "Удаление: полное удаление аккаунта — Настройки → Удалить аккаунт. Все персональные данные удаляются в течение 30 дней (некоторые служебные журналы хранятся дольше по закону).",
        "Портируемость: запрос копии ваших данных — по email ниже.",
        "Возражение: возражение против обработки — по email ниже.",
      ],
    },
    {
      id: "retention",
      title: "6. Срок хранения",
      paragraphs: [
        "Активный аккаунт: данные хранятся, пока вы не удалите аккаунт.",
        "Удалённый аккаунт: персональные данные удаляются в течение 30 дней. Обезличенные служебные журналы могут храниться дольше.",
        "Отклики и переписка: удаляются вместе с аккаунтом.",
        "Оплата: налоговые записи хранятся согласно законам Узбекистана.",
      ],
    },
    {
      id: "security",
      title: "7. Безопасность",
      paragraphs: [
        "Все данные передаются в зашифрованном виде (HTTPS/TLS).",
        "Пароли хешируются в одном направлении (никогда не хранятся в открытом виде).",
        "Файлы (резюме, фото) защищены политиками RLS в Supabase Storage.",
        "При инциденте безопасности вы будете уведомлены незамедлительно.",
      ],
    },
    {
      id: "children",
      title: "8. Дети",
      paragraphs: [
        "Yollla предназначен для пользователей 16 лет и старше. Если мы случайно собрали данные лица младше 16 лет, мы их немедленно удалим.",
      ],
    },
    {
      id: "changes",
      title: "9. Изменения политики",
      paragraphs: [
        "Yollla может обновить эту политику. О существенных изменениях вы получите уведомление в приложении и по email. Новая версия действует с даты вступления в силу.",
      ],
    },
  ],
  contactLead: "По вопросам и для реализации ваших прав пишите нам:",
  contactEmail: SUPPORT_EMAIL,
};

// ────────────────────────────────────────────────────────────────────────────
// PRIVACY POLICY — en
// ────────────────────────────────────────────────────────────────────────────
const privacyEn: LegalDocument = {
  title: "Privacy Policy",
  effectiveDate: LEGAL_EFFECTIVE_DATE,
  intro:
    "Yollla is a mobile job-search and recruitment marketplace for Uzbekistan. This policy explains what we collect, why, who we share it with, and your choices.",
  sections: [
    {
      id: "collect",
      title: "1. Information we collect",
      paragraphs: [
        "Account: email, password (hashed by our auth provider), phone number — to create and secure your account, sign in.",
        "Profile and CV: name, headline, bio, photo, work experience, education, skills, desired pay, availability, uploaded resume files, contact links — to build your profile, let employers evaluate you, and apply to jobs.",
        "Location: approximate or precise coordinates (only if you grant permission or set a location) — to show nearby jobs and estimate commute distance.",
        "Applications: cover letters, screening answers, attached resume — to submit applications to employers.",
        "Messages: chat content between seekers and employers — for in-app messaging.",
        "Employer data: company name, profile, team, job postings — to operate the employer side.",
        "Device and usage: push notification token, device platform, bookmarks, searches — to deliver notifications and personalize the feed.",
      ],
    },
    {
      id: "use",
      title: "2. How we use your information",
      paragraphs: [
        "Operate the marketplace: post jobs, search, apply, manage applicants, chat.",
        "Match seekers with jobs (including an optional AI \"good match\" assessment).",
        "Send notifications you've enabled (in-app, push, and — if you connect it — Telegram).",
        "Keep the service secure and prevent abuse.",
        "We do NOT sell your personal data, and we do NOT use it for third-party advertising.",
      ],
    },
    {
      id: "visibility",
      title: "3. Visibility to other users",
      paragraphs: [
        "When you mark yourself \"open to work,\" employers can find your public profile card (name, headline, photo, city, skills).",
        "Your exact home coordinates, phone, email, bio and home address are NOT shown to other users; precise applicant location is shared with an employer only for the specific job you applied to.",
        "Employer job postings and company profiles are public within the app.",
      ],
    },
    {
      id: "processors",
      title: "4. Service providers we share data with",
      paragraphs: [
        "To operate our service we share limited data with trusted providers:",
        "Supabase — backend, auth, database, file storage.",
        "Firebase Cloud Messaging (Google) — push notification delivery.",
        "Yandex Maps — maps, geolocation and geocoding.",
        "Telegram Gateway — phone verification codes and bot notifications (if connected).",
        "Sentry — error and performance monitoring (no PII sent).",
        "Vercel, Google Analytics 4, Yandex.Metrica, Meta Pixel, PostHog — anonymous usage analytics.",
        "Anthropic (Claude) — optional AI assistance (resume parsing, job-post drafting).",
      ],
    },
    {
      id: "rights",
      title: "5. Your rights",
      paragraphs: [
        "Access: view and edit your account data — via Profile settings.",
        "Correction: fix incorrect data — same place.",
        "Deletion: fully delete your account — Settings → Delete account. All personal data is deleted within 30 days (some service logs are retained longer as required by law).",
        "Portability: request a copy of your data — via the email below.",
        "Objection: object to processing — via the email below.",
      ],
    },
    {
      id: "retention",
      title: "6. Retention",
      paragraphs: [
        "Active account: data retained until you delete the account.",
        "Deleted account: personal data deleted within 30 days. Anonymized service logs may be retained longer.",
        "Applications and messages: deleted with the account.",
        "Payments: tax records retained per Uzbekistan law.",
      ],
    },
    {
      id: "security",
      title: "7. Security",
      paragraphs: [
        "All data is transmitted encrypted (HTTPS/TLS).",
        "Passwords are one-way hashed (never stored in cleartext).",
        "Files (resumes, images) are protected by RLS policies in Supabase Storage.",
        "In case of a security incident, you will be notified promptly.",
      ],
    },
    {
      id: "children",
      title: "8. Children",
      paragraphs: [
        "Yollla is intended for users 16 and older. If we accidentally collect data from a person under 16, we will delete it immediately.",
      ],
    },
    {
      id: "changes",
      title: "9. Changes to this policy",
      paragraphs: [
        "Yollla may update this policy. You will be notified of material changes in the app and by email. The new version takes effect on the effective date.",
      ],
    },
  ],
  contactLead: "For questions or to exercise your rights, contact us:",
  contactEmail: SUPPORT_EMAIL,
};

// ────────────────────────────────────────────────────────────────────────────
// TERMS OF SERVICE — uz
// ────────────────────────────────────────────────────────────────────────────
const termsUz: LegalDocument = {
  title: "Foydalanish shartlari",
  effectiveDate: LEGAL_EFFECTIVE_DATE,
  intro:
    "Yollla xizmatidan foydalanish uchun ushbu shartlarni qabul qilishingiz kerak. Xizmatga kirsangiz — siz ular bilan roziligingizni tasdiqlaysiz.",
  sections: [
    {
      id: "eligibility",
      title: "1. Muvofiqlik",
      paragraphs: [
        "Yollladan foydalanish uchun kamida 16 yoshda bo'lishingiz kerak.",
        "Rost va aniq ma'lumot berishga majbursiz. Yolg'on identifikatsiya — hisobingiz bloklanishi uchun asosdir.",
        "Bitta jismoniy shaxs bitta hisob yaratadi. Ish beruvchi jamoasi bir nechta hisob yaratishi mumkin.",
      ],
    },
    {
      id: "account",
      title: "2. Hisob mas'uliyati",
      paragraphs: [
        "Parolingizni maxfiy tuting; hisobingizdan har qanday harakatlar uchun siz javobgarsiz.",
        "Ruxsatsiz kirish holatini sezsangiz, darhol bizga xabar bering.",
        "Bir vaqtning o'zida bir yoki bir nechta qurilmadan foydalanishingiz mumkin.",
      ],
    },
    {
      id: "seeker",
      title: "3. Ish qidiruvchi majburiyatlari",
      paragraphs: [
        "Rezyume va ariza ma'lumotlaringiz to'g'ri bo'lsin. Yolg'on rezyume ariza rad etilishi va hisob bloklanishi uchun asosdir.",
        "Ish beruvchi bilan yozishmalarni maxfiy tuting va faqat professional maqsadlarda ishlating.",
        "Ish beruvchi bergan ma'lumotlarni (masalan, kompaniya sirlari) uchinchi shaxsga uzatmang.",
      ],
    },
    {
      id: "employer",
      title: "4. Ish beruvchi majburiyatlari",
      paragraphs: [
        "Ish e'lonlaringiz aniq va halol bo'lsin. Xayoliy ish e'lonlari, MLM, noqonuniy tuzilmalar (jinsi, yoshi, dini, millati bo'yicha kamsitish) taqiqlanadi.",
        "Ariza bergan ish qidiruvchilarning shaxsiy ma'lumotlarini faqat yollash maqsadida ishlating. Boshqa maqsadda uzatish yoki sotish taqiqlanadi.",
        "Yolg'on kompaniya profillari yaratish yoki boshqa foydalanuvchini yollash uchun sotib olishga urinish taqiqlanadi.",
        "Yollla ba'zi ish e'lonlarini yoki kompaniyalarni oldindan tekshiruvsiz e'lon qilishi mumkin — siz to'liq mazmun uchun javobgarsiz.",
      ],
    },
    {
      id: "content",
      title: "5. Taqiqlangan mazmun",
      paragraphs: [
        "Kamsitish, tahdid, tahqir, qonunbuzarlik, MLM tarqatish, ochiq/pornografik mazmun taqiqlanadi.",
        "Ish beruvchining ish e'loni jinsi, yoshi, millati, dini, oilaviy holati bo'yicha talab qo'yishi taqiqlanadi.",
        "Har qanday foydalanuvchi shubhali mazmunni shikoyat qila oladi. Yollla 24 soat ichida ko'rib chiqadi.",
        "Yollla har qanday mazmun yoki hisobni oldindan xabar bermasdan olib tashlash yoki bloklash huquqiga ega.",
      ],
    },
    {
      id: "payments",
      title: "6. To'lovlar",
      paragraphs: [
        "Yolllada birinchi ish e'loni bepul; keyingi e'lonlar uchun to'lov olinadi (narxlar /pricing sahifasida).",
        "Ilg'or paketlar (TOP, Brend, Premium) ixtiyoriy va xarid vaqtida narxda bo'ladi.",
        "To'lov Click, Payme yoki bank o'tkazmasi orqali. To'lov muvaffaqiyatli o'tgach ariza qaytarilmaydi (ish e'lon qilingandan keyin).",
        "Yollla narxlarni istalgan vaqtda o'zgartirishi mumkin — o'zgarish e'lon qilingan sanadan boshlab yangi to'lovlarga qo'llaniladi.",
      ],
    },
    {
      id: "termination",
      title: "7. To'xtatish va bekor qilish",
      paragraphs: [
        "Siz hisobingizni istalgan vaqtda o'chirishingiz mumkin (Sozlamalar → Hisobni o'chirish).",
        "Yollla ushbu shartlarni buzganingizni aniqlagan taqdirda hisobingizni to'xtatishi yoki o'chirishi mumkin.",
        "Hisobingiz o'chirilsa, sizga hech qanday to'lov qaytarilmaydi (o'chirish sabab bo'lgan hollarda).",
      ],
    },
    {
      id: "disclaimer",
      title: "8. Kafolatlar va javobgarlik",
      paragraphs: [
        "Yollla ishga olish yoki yollash natijalarini kafolatlamaydi — biz platforma, ish beruvchi va ish qidiruvchi mustaqil shaxslar.",
        "Ish beruvchi bergan ma'lumot yoki ish qidiruvchi taqdim etgan rezyume mazmuni uchun Yollla javobgar emas.",
        "Yollla xizmatining uzluksizligini kafolatlamaydi (planlanmagan texnik ta'mirlar, uchinchi tomon xizmatlari to'xtashi bo'lishi mumkin).",
        "Yollla javobgarligi qonun bilan ruxsat etilgan darajaga cheklangan.",
      ],
    },
    {
      id: "law",
      title: "9. Qo'llaniladigan qonun",
      paragraphs: [
        "Ushbu shartlar O'zbekiston Respublikasi qonunlariga muvofiq talqin qilinadi.",
        "Har qanday tortishuvlar Toshkent shahridagi vakolatli sudda hal qilinadi.",
      ],
    },
    {
      id: "changes",
      title: "10. Shartlarga o'zgartirishlar",
      paragraphs: [
        "Yollla ushbu shartlarni yangilashi mumkin. Muhim o'zgarishlar oldindan e'lon qilinadi. Yangi versiya kuchga kirgan sanadan boshlab qo'llaniladi. O'zgarishlarga rozi bo'lmasangiz — hisobingizni o'chiring.",
      ],
    },
  ],
  contactLead: "Savollar bo'lsa biz bilan bog'laning:",
  contactEmail: SUPPORT_EMAIL,
};

// ────────────────────────────────────────────────────────────────────────────
// TERMS OF SERVICE — ru
// ────────────────────────────────────────────────────────────────────────────
const termsRu: LegalDocument = {
  title: "Условия использования",
  effectiveDate: LEGAL_EFFECTIVE_DATE,
  intro:
    "Чтобы пользоваться Yollla, вы должны принять эти условия. Заходя в сервис, вы подтверждаете согласие с ними.",
  sections: [
    {
      id: "eligibility",
      title: "1. Право использования",
      paragraphs: [
        "Для использования Yollla вам должно быть не менее 16 лет.",
        "Вы обязаны предоставлять правдивую и точную информацию. Ложная идентификация — основание для блокировки аккаунта.",
        "Один физический человек создаёт один аккаунт. Команда работодателя может создавать несколько аккаунтов.",
      ],
    },
    {
      id: "account",
      title: "2. Ответственность за аккаунт",
      paragraphs: [
        "Держите пароль в секрете; вы отвечаете за все действия с вашего аккаунта.",
        "Если заметили несанкционированный вход — немедленно сообщите нам.",
        "Вы можете использовать сервис с одного или нескольких устройств одновременно.",
      ],
    },
    {
      id: "seeker",
      title: "3. Обязательства соискателя",
      paragraphs: [
        "Ваше резюме и данные откликов должны быть точными. Ложное резюме — основание для отклонения отклика и блокировки аккаунта.",
        "Держите переписку с работодателем конфиденциальной и используйте только в профессиональных целях.",
        "Не передавайте информацию, полученную от работодателя (например, коммерческие тайны), третьим лицам.",
      ],
    },
    {
      id: "employer",
      title: "4. Обязательства работодателя",
      paragraphs: [
        "Ваши вакансии должны быть точными и честными. Фиктивные вакансии, MLM, незаконные схемы (дискриминация по полу, возрасту, религии, национальности) запрещены.",
        "Используйте персональные данные откликнувшихся соискателей только для целей найма. Передача или продажа для других целей запрещена.",
        "Создание поддельных профилей компаний или попытки покупки для найма другого пользователя запрещены.",
        "Yollla может публиковать некоторые вакансии или компании без предварительной проверки — вы полностью отвечаете за содержание.",
      ],
    },
    {
      id: "content",
      title: "5. Запрещённое содержание",
      paragraphs: [
        "Дискриминация, угрозы, оскорбления, нарушение закона, распространение MLM, откровенный/порнографический контент запрещены.",
        "Вакансии, содержащие требования по полу, возрасту, национальности, религии или семейному положению, запрещены.",
        "Любой пользователь может пожаловаться на подозрительное содержание. Yollla рассматривает жалобы в течение 24 часов.",
        "Yollla вправе удалить или заблокировать любое содержание или аккаунт без предварительного уведомления.",
      ],
    },
    {
      id: "payments",
      title: "6. Оплата",
      paragraphs: [
        "Первая вакансия бесплатна; за последующие взимается плата (цены на странице /pricing).",
        "Пакеты продвижения (TOP, Бренд, Премиум) необязательны и оплачиваются при покупке.",
        "Оплата через Click, Payme или банковский перевод. После успешной оплаты возврат не производится (после публикации вакансии).",
        "Yollla может изменить цены в любое время — изменения применяются к новым платежам с даты объявления.",
      ],
    },
    {
      id: "termination",
      title: "7. Приостановка и прекращение",
      paragraphs: [
        "Вы можете удалить аккаунт в любое время (Настройки → Удалить аккаунт).",
        "Yollla может приостановить или удалить ваш аккаунт при нарушении настоящих условий.",
        "При удалении аккаунта возврат уплаченных средств не производится (если удаление связано с нарушением).",
      ],
    },
    {
      id: "disclaimer",
      title: "8. Гарантии и ответственность",
      paragraphs: [
        "Yollla не гарантирует результат найма — мы платформа, а работодатель и соискатель — независимые лица.",
        "Yollla не отвечает за содержание, предоставленное работодателем или соискателем.",
        "Yollla не гарантирует бесперебойность сервиса (возможны плановые технические работы, сбои сторонних сервисов).",
        "Ответственность Yollla ограничена в рамках, разрешённых законом.",
      ],
    },
    {
      id: "law",
      title: "9. Применимое право",
      paragraphs: [
        "Настоящие условия толкуются в соответствии с законодательством Республики Узбекистан.",
        "Все споры разрешаются в компетентном суде города Ташкент.",
      ],
    },
    {
      id: "changes",
      title: "10. Изменения условий",
      paragraphs: [
        "Yollla может обновлять эти условия. О существенных изменениях сообщается заранее. Новая версия действует с даты вступления в силу. Если не согласны с изменениями — удалите аккаунт.",
      ],
    },
  ],
  contactLead: "По вопросам пишите нам:",
  contactEmail: SUPPORT_EMAIL,
};

// ────────────────────────────────────────────────────────────────────────────
// TERMS OF SERVICE — en
// ────────────────────────────────────────────────────────────────────────────
const termsEn: LegalDocument = {
  title: "Terms of Service",
  effectiveDate: LEGAL_EFFECTIVE_DATE,
  intro:
    "To use Yollla you must accept these terms. By accessing the service you confirm your agreement.",
  sections: [
    {
      id: "eligibility",
      title: "1. Eligibility",
      paragraphs: [
        "You must be at least 16 years old to use Yollla.",
        "You must provide truthful and accurate information. False identification is grounds for account blocking.",
        "One individual creates one account. Employer teams may create multiple accounts.",
      ],
    },
    {
      id: "account",
      title: "2. Account responsibility",
      paragraphs: [
        "Keep your password secret; you are responsible for all actions from your account.",
        "If you notice unauthorized access, notify us immediately.",
        "You may use the service from one or several devices simultaneously.",
      ],
    },
    {
      id: "seeker",
      title: "3. Seeker obligations",
      paragraphs: [
        "Your resume and application data must be accurate. False resume is grounds for application rejection and account blocking.",
        "Keep communication with the employer confidential and use it for professional purposes only.",
        "Do not share information provided by the employer (e.g., trade secrets) with third parties.",
      ],
    },
    {
      id: "employer",
      title: "4. Employer obligations",
      paragraphs: [
        "Your job postings must be accurate and honest. Fictitious postings, MLM, illegal schemes (discrimination based on gender, age, religion, nationality) are prohibited.",
        "Use personal data of applicants only for hiring purposes. Transfer or sale for other purposes is prohibited.",
        "Creating fake company profiles or purchasing to hire another user is prohibited.",
        "Yollla may publish some postings or companies without pre-review — you are fully responsible for the content.",
      ],
    },
    {
      id: "content",
      title: "5. Prohibited content",
      paragraphs: [
        "Discrimination, threats, insults, illegal activity, MLM distribution, explicit/pornographic content are prohibited.",
        "Job postings with requirements based on gender, age, nationality, religion, or family status are prohibited.",
        "Any user can report suspicious content. Yollla reviews reports within 24 hours.",
        "Yollla reserves the right to remove or block any content or account without prior notice.",
      ],
    },
    {
      id: "payments",
      title: "6. Payments",
      paragraphs: [
        "The first job posting is free; subsequent postings are paid (prices at /pricing).",
        "Promotion packages (TOP, Brand, Premium) are optional and priced at purchase.",
        "Payment via Click, Payme or bank transfer. After successful payment no refund is provided (after job publication).",
        "Yollla may change prices at any time — changes apply to new payments from the announced date.",
      ],
    },
    {
      id: "termination",
      title: "7. Suspension and termination",
      paragraphs: [
        "You can delete your account at any time (Settings → Delete account).",
        "Yollla may suspend or delete your account for violation of these terms.",
        "If your account is deleted, no refund is provided (in violation-related cases).",
      ],
    },
    {
      id: "disclaimer",
      title: "8. Warranties and liability",
      paragraphs: [
        "Yollla does not guarantee hiring outcomes — we are a platform; employer and seeker are independent parties.",
        "Yollla is not responsible for content provided by the employer or the seeker.",
        "Yollla does not guarantee uninterrupted service (planned maintenance and third-party outages may occur).",
        "Yollla's liability is limited to the extent permitted by law.",
      ],
    },
    {
      id: "law",
      title: "9. Governing law",
      paragraphs: [
        "These terms are interpreted under the laws of the Republic of Uzbekistan.",
        "All disputes are resolved in the competent court of Tashkent city.",
      ],
    },
    {
      id: "changes",
      title: "10. Changes to terms",
      paragraphs: [
        "Yollla may update these terms. Material changes are announced in advance. The new version takes effect on the effective date. If you disagree with changes, delete your account.",
      ],
    },
  ],
  contactLead: "For questions contact us:",
  contactEmail: SUPPORT_EMAIL,
};

// ────────────────────────────────────────────────────────────────────────────
// Registries + accessor
// ────────────────────────────────────────────────────────────────────────────
const privacyByLocale: Record<LegalLocale, LegalDocument> = {
  uz: privacyUz,
  ru: privacyRu,
  en: privacyEn,
};

const termsByLocale: Record<LegalLocale, LegalDocument> = {
  uz: termsUz,
  ru: termsRu,
  en: termsEn,
};

export function getPrivacyPolicy(locale: string): LegalDocument {
  const key = (locale as LegalLocale) in privacyByLocale
    ? (locale as LegalLocale)
    : "uz";
  return privacyByLocale[key];
}

export function getTermsOfService(locale: string): LegalDocument {
  const key = (locale as LegalLocale) in termsByLocale
    ? (locale as LegalLocale)
    : "uz";
  return termsByLocale[key];
}
