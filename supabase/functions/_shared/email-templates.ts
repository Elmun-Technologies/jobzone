// email-templates.ts — every email Yolla sends, in uz/ru/en.
//
// Pure: no Deno APIs, no network, no imports beyond the locale helpers it
// shares with the Telegram/push text. Each builder returns { subject, html,
// text } and the caller sends it; that keeps the copy testable and keeps the
// sender (email.ts) free of markup.
//
// House rules for the markup, learned the hard way by everyone who has ever
// shipped HTML mail:
//   • tables + inline styles only (Gmail strips <style>, Outlook ignores flex);
//   • one 600px column, 16px+ type, tap targets ≥ 44px — this audience opens
//     mail on a phone;
//   • a text/plain twin for every message (spam filters weigh its absence);
//   • a preheader line, because the inbox preview is half the open decision;
//   • every non-transactional mail carries a visible unsubscribe link that
//     works without signing in (the token RPC in migration 0084).
//
// Copy is Uzbek-first: uz is written natively, ru/en are the translations.

import {
  type InviteJob,
  localizedNotificationText,
  type Loc,
  normalizeLocale,
} from "./notification-text.ts";

export type { InviteJob, Loc };
export { normalizeLocale };

export interface EmailContent {
  subject: string;
  html: string;
  text: string;
}

/** Links every mail needs: where the product lives, and how to opt out. */
export interface EmailLinks {
  /** Site origin, no trailing slash (e.g. https://www.yollla.uz). */
  site: string;
  /** Locale-prefixed unsubscribe URL carrying the recipient's token. */
  unsubscribeUrl?: string;
  /** Notification-settings page (locale-prefixed). */
  prefsUrl?: string;
}

export interface JobItem {
  id?: string;
  title: string;
  company?: string | null;
  city?: string | null;
  /** Why this job reached the recipient: their saved search's name, or the
   *  followed company. Rendered as a small caption on the card. */
  reason?: string | null;
}

// ---------------------------------------------------------------------------
// Brand tokens (kept in sync with design_system/JzColors + webapp theme)
// ---------------------------------------------------------------------------
const INK = "#0A0A0A";
const VOLT = "#C7FB00";
const PAPER = "#FFFFFF";
const CANVAS = "#F4F4F2";
const BORDER = "#E4E4E0";
const MUTED = "#6B6B66";
const FONT = "Archivo, 'Helvetica Neue', Helvetica, Arial, sans-serif";

// ---------------------------------------------------------------------------
// Copy
// ---------------------------------------------------------------------------
interface Strings {
  tagline: string;
  greeting: string; // {name}
  greetingPlain: string;
  // welcome
  welcomeSubject: string;
  welcomeConfirmed: string;
  welcomeSeekerIntro: string;
  welcomeEmployerIntro: string;
  welcomeSeekerSteps: string[];
  welcomeEmployerSteps: string[];
  welcomeSeekerCta: string;
  welcomeEmployerCta: string;
  welcomeAlertsHint: string;
  // job alerts
  alertSubjectOne: string;
  alertSubjectMany: string; // {count}
  alertHeadingOne: string;
  alertHeadingMany: string; // {count}
  alertIntro: string; // {reasons}
  alertCta: string;
  alertViewJob: string;
  alertReasonSearch: string; // {name}
  alertReasonCompany: string; // {name}
  // notification wrappers
  messageSubject: string;
  messageCta: string;
  applicationSubject: string;
  applicationCta: string;
  inviteSubject: string;
  inviteCta: string;
  reviewCta: string;
  marketingCta: string;
  openApp: string;
  // footer
  footerWhyAlert: string;
  footerWhyAccount: string;
  footerWhyMarketing: string;
  unsubscribe: string;
  managePrefs: string;
  footerLegal: string;
}

const COPY: Record<Loc, Strings> = {
  uz: {
    tagline: "O'zbekistondagi ishonchli ish bozori",
    greeting: "Assalomu alaykum, {name}!",
    greetingPlain: "Assalomu alaykum!",
    welcomeSubject: "Yollaga xush kelibsiz",
    welcomeConfirmed: "Email manzilingiz tasdiqlandi — hisobingiz tayyor.",
    welcomeSeekerIntro:
      "Yolla — ishchi kasblar uchun ish e'lonlari platformasi. Bu yerda ish beruvchilar tekshiriladi, maosh esa e'londa ochiq yoziladi.",
    welcomeEmployerIntro:
      "Yolla — ishchi kasblar uchun xodim topish platformasi. Vakansiyangiz mobil ilova va saytda bir vaqtda ko'rinadi.",
    welcomeSeekerSteps: [
      "Rezyumeni to'ldiring — ish beruvchilar sizni o'zi topadi.",
      "Yo'nalish va shaharni saqlab qo'ying — yangi vakansiya chiqsa, xabar beramiz.",
      "Yoqqan ishga bir bosishda ariza yuboring.",
    ],
    welcomeEmployerSteps: [
      "Kompaniya sahifasini to'ldiring — ishonch shundan boshlanadi.",
      "Birinchi vakansiyani joylang, u darhol e'lon qilinadi.",
      "Arizalarni bitta oynada ko'rib chiqing va nomzod bilan yozishing.",
    ],
    welcomeSeekerCta: "Vakansiyalarni ko'rish",
    welcomeEmployerCta: "Vakansiya joylash",
    welcomeAlertsHint:
      "Qidiruvni saqlab qo'ysangiz, unga mos yangi ish chiqishi bilan email va bildirishnoma yuboramiz.",
    alertSubjectOne: "Sizga mos yangi vakansiya",
    alertSubjectMany: "{count} ta yangi vakansiya sizga mos keldi",
    alertHeadingOne: "Sizga mos yangi vakansiya",
    alertHeadingMany: "{count} ta yangi vakansiya",
    alertIntro: "Saqlab qo'yganingiz bo'yicha: {reasons}",
    alertCta: "Barcha vakansiyalarni ko'rish",
    alertViewJob: "Batafsil",
    alertReasonSearch: "«{name}» qidiruvi",
    alertReasonCompany: "{name} kompaniyasi",
    messageSubject: "Sizga yangi xabar keldi",
    messageCta: "Xabarni o'qish",
    applicationSubject: "Ariza holati yangilandi",
    applicationCta: "Arizani ko'rish",
    inviteSubject: "Sizga ish taklifi bor",
    inviteCta: "Taklifni ko'rish",
    reviewCta: "Sharhni ko'rish",
    marketingCta: "Yollani ochish",
    openApp: "Yollani ochish",
    footerWhyAlert:
      "Bu xat Yollada saqlagan qidiruvingiz yoki obuna bo'lgan kompaniyangiz bo'yicha yuborildi.",
    footerWhyAccount: "Bu xat Yolladagi hisobingiz bo'yicha yuborildi.",
    footerWhyMarketing:
      "Bu xat Yolla yangiliklariga obuna bo'lganingiz uchun yuborildi.",
    unsubscribe: "Obunani bekor qilish",
    managePrefs: "Bildirishnoma sozlamalari",
    footerLegal: "Yolla — ish qidirish va xodim topish platformasi.",
  },
  ru: {
    tagline: "Надёжный рынок труда Узбекистана",
    greeting: "Здравствуйте, {name}!",
    greetingPlain: "Здравствуйте!",
    welcomeSubject: "Добро пожаловать в Yolla",
    welcomeConfirmed: "Ваш email подтверждён — аккаунт готов к работе.",
    welcomeSeekerIntro:
      "Yolla — площадка вакансий для рабочих профессий. Работодатели проходят проверку, а зарплата указывается прямо в объявлении.",
    welcomeEmployerIntro:
      "Yolla — площадка для найма рабочих специальностей. Ваша вакансия появляется в мобильном приложении и на сайте одновременно.",
    welcomeSeekerSteps: [
      "Заполните резюме — работодатели найдут вас сами.",
      "Сохраните направление и город — сообщим о новых вакансиях.",
      "Откликайтесь на подходящие вакансии в один клик.",
    ],
    welcomeEmployerSteps: [
      "Заполните страницу компании — доверие начинается с неё.",
      "Разместите первую вакансию, она публикуется сразу.",
      "Смотрите отклики в одном окне и пишите кандидатам.",
    ],
    welcomeSeekerCta: "Смотреть вакансии",
    welcomeEmployerCta: "Разместить вакансию",
    welcomeAlertsHint:
      "Сохраните поиск — и мы пришлём письмо и уведомление, как только появится подходящая вакансия.",
    alertSubjectOne: "Новая подходящая вакансия",
    alertSubjectMany: "{count} новых вакансий по вашему поиску",
    alertHeadingOne: "Новая подходящая вакансия",
    alertHeadingMany: "{count} новых вакансий",
    alertIntro: "По вашим сохранённым: {reasons}",
    alertCta: "Смотреть все вакансии",
    alertViewJob: "Подробнее",
    alertReasonSearch: "поиск «{name}»",
    alertReasonCompany: "компания {name}",
    messageSubject: "Вам пришло новое сообщение",
    messageCta: "Прочитать сообщение",
    applicationSubject: "Статус отклика обновлён",
    applicationCta: "Открыть отклик",
    inviteSubject: "Вас приглашают на работу",
    inviteCta: "Посмотреть приглашение",
    reviewCta: "Посмотреть отзыв",
    marketingCta: "Открыть Yolla",
    openApp: "Открыть Yolla",
    footerWhyAlert:
      "Вы получили это письмо по сохранённому поиску или подписке на компанию в Yolla.",
    footerWhyAccount: "Вы получили это письмо как владелец аккаунта в Yolla.",
    footerWhyMarketing:
      "Вы получили это письмо, потому что подписаны на новости Yolla.",
    unsubscribe: "Отписаться",
    managePrefs: "Настройки уведомлений",
    footerLegal: "Yolla — площадка поиска работы и найма.",
  },
  en: {
    tagline: "Uzbekistan's trusted job marketplace",
    greeting: "Hi {name},",
    greetingPlain: "Hi there,",
    welcomeSubject: "Welcome to Yolla",
    welcomeConfirmed: "Your email is confirmed — your account is ready.",
    welcomeSeekerIntro:
      "Yolla is a job marketplace for blue-collar work. Employers are verified and the pay is stated right in the posting.",
    welcomeEmployerIntro:
      "Yolla is where you hire for blue-collar roles. Your vacancy shows up in the mobile app and on the web at the same time.",
    welcomeSeekerSteps: [
      "Fill in your résumé — employers will find you.",
      "Save a field and a city — we'll email you when a matching job appears.",
      "Apply to any job in a single tap.",
    ],
    welcomeEmployerSteps: [
      "Complete your company page — trust starts there.",
      "Post your first vacancy; it goes live immediately.",
      "Review applicants in one place and message candidates.",
    ],
    welcomeSeekerCta: "Browse jobs",
    welcomeEmployerCta: "Post a vacancy",
    welcomeAlertsHint:
      "Save a search and we'll send an email and a notification as soon as a matching job is posted.",
    alertSubjectOne: "A new job matches your search",
    alertSubjectMany: "{count} new jobs match your search",
    alertHeadingOne: "A new job matches your search",
    alertHeadingMany: "{count} new jobs",
    alertIntro: "From what you saved: {reasons}",
    alertCta: "See all jobs",
    alertViewJob: "View job",
    alertReasonSearch: "“{name}” search",
    alertReasonCompany: "{name}",
    messageSubject: "You have a new message",
    messageCta: "Read the message",
    applicationSubject: "Your application was updated",
    applicationCta: "Open application",
    inviteSubject: "You've been invited to apply",
    inviteCta: "See the invitation",
    reviewCta: "See the review",
    marketingCta: "Open Yolla",
    openApp: "Open Yolla",
    footerWhyAlert:
      "You're getting this because of a search you saved or a company you follow on Yolla.",
    footerWhyAccount: "You're getting this because you have a Yolla account.",
    footerWhyMarketing:
      "You're getting this because you're subscribed to Yolla news.",
    unsubscribe: "Unsubscribe",
    managePrefs: "Notification settings",
    footerLegal: "Yolla — find work, hire people.",
  },
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** HTML-escape every interpolated value. Job titles and company names are
 *  user-authored; none of them may reach the markup unescaped. */
export function esc(v: unknown): string {
  return String(v ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function fill(template: string, vars: Record<string, string | number>): string {
  return template.replace(/\{(\w+)\}/g, (m, k) => String(vars[k] ?? m));
}

/** Russian needs 1 / 2–4 / 5+ forms; uz and en don't inflect here. */
function alertSubject(loc: Loc, count: number): string {
  const s = COPY[loc];
  if (count <= 1) return s.alertSubjectOne;
  if (loc !== "ru") return fill(s.alertSubjectMany, { count });
  const mod10 = count % 10;
  const mod100 = count % 100;
  const noun = mod10 === 1 && mod100 !== 11
    ? "новая вакансия"
    : mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)
    ? "новые вакансии"
    : "новых вакансий";
  return `${count} ${noun} по вашему поиску`;
}

function alertHeading(loc: Loc, count: number): string {
  const s = COPY[loc];
  if (count <= 1) return s.alertHeadingOne;
  if (loc !== "ru") return fill(s.alertHeadingMany, { count });
  const mod10 = count % 10;
  const mod100 = count % 100;
  const noun = mod10 === 1 && mod100 !== 11
    ? "новая вакансия"
    : mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)
    ? "новые вакансии"
    : "новых вакансий";
  return `${count} ${noun}`;
}

/** Only http(s) links may reach an <a href> or the plain-text body. */
function safeUrl(url: string | undefined | null): string | null {
  if (!url) return null;
  const trimmed = String(url).trim();
  return /^https?:\/\//i.test(trimmed) ? trimmed : null;
}

interface LayoutInput {
  loc: Loc;
  preheader: string;
  heading: string;
  /** Paragraphs above the CTA. Plain text; escaped here. */
  intro?: string[];
  /** Raw (already-escaped) HTML injected between intro and CTA. */
  bodyHtml?: string;
  /** Plain-text twin of bodyHtml. */
  bodyText?: string;
  cta?: { label: string; url: string };
  /** Which "why am I getting this?" line the footer shows. */
  why: "alert" | "account" | "marketing";
  /** The `scope` the unsubscribe link should switch off. */
  unsubscribeScope?: string;
  links: EmailLinks;
}

function withScope(url: string | null, scope?: string): string | null {
  if (!url || !scope) return url;
  return url.includes("?")
    ? `${url}&scope=${encodeURIComponent(scope)}`
    : `${url}?scope=${encodeURIComponent(scope)}`;
}

function layout(input: LayoutInput): { html: string; text: string } {
  const s = COPY[input.loc];
  const site = safeUrl(input.links.site) ?? "https://www.yollla.uz";
  const unsub = withScope(
    safeUrl(input.links.unsubscribeUrl),
    input.unsubscribeScope,
  );
  const prefs = safeUrl(input.links.prefsUrl);
  const cta = input.cta && safeUrl(input.cta.url)
    ? { label: input.cta.label, url: safeUrl(input.cta.url)! }
    : null;
  const why = input.why === "alert"
    ? s.footerWhyAlert
    : input.why === "marketing"
    ? s.footerWhyMarketing
    : s.footerWhyAccount;

  const introHtml = (input.intro ?? [])
    .map(
      (p) =>
        `<p style="margin:0 0 14px;font-size:16px;line-height:26px;color:${INK};">${
          esc(p)
        }</p>`,
    )
    .join("");

  const ctaHtml = cta
    ? `<table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:26px 0 6px;">
         <tr><td style="border-radius:12px;background:${VOLT};">
           <a href="${esc(cta.url)}"
              style="display:inline-block;padding:14px 26px;font-family:${FONT};font-size:16px;font-weight:700;color:${INK};text-decoration:none;border-radius:12px;">${
      esc(cta.label)
    }</a>
         </td></tr>
       </table>`
    : "";

  const footerLinks = [
    prefs ? `<a href="${esc(prefs)}" style="color:${MUTED};">${
      esc(s.managePrefs)
    }</a>` : null,
    unsub ? `<a href="${esc(unsub)}" style="color:${MUTED};">${
      esc(s.unsubscribe)
    }</a>` : null,
  ].filter(Boolean).join(" &nbsp;·&nbsp; ");

  const html =
    `<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html lang="${input.loc}" xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<meta name="color-scheme" content="light" />
<title>${esc(input.heading)}</title>
</head>
<body style="margin:0;padding:0;background:${CANVAS};">
<div style="display:none;max-height:0;overflow:hidden;opacity:0;">${
      esc(input.preheader)
    }</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:${CANVAS};padding:24px 12px;">
  <tr><td align="center">
    <table role="presentation" width="600" cellpadding="0" cellspacing="0" border="0" style="width:100%;max-width:600px;font-family:${FONT};">
      <tr><td style="background:${INK};border-radius:18px 18px 0 0;padding:22px 28px;">
        <a href="${
      esc(site)
    }" style="text-decoration:none;display:inline-block;">
          <span style="display:inline-block;background:${VOLT};color:${INK};font-size:18px;font-weight:800;line-height:1;padding:8px 10px;border-radius:10px 10px 10px 2px;">yo</span>
          <span style="color:${PAPER};font-size:20px;font-weight:800;letter-spacing:-0.3px;padding-left:8px;vertical-align:middle;">Yolla</span>
        </a>
        <div style="color:#9A9A93;font-size:12px;padding-top:8px;">${
      esc(s.tagline)
    }</div>
      </td></tr>
      <tr><td style="background:${PAPER};padding:28px;">
        <h1 style="margin:0 0 16px;font-size:22px;line-height:30px;color:${INK};font-weight:800;">${
      esc(input.heading)
    }</h1>
        ${introHtml}
        ${input.bodyHtml ?? ""}
        ${ctaHtml}
      </td></tr>
      <tr><td style="background:${PAPER};border-radius:0 0 18px 18px;border-top:1px solid ${BORDER};padding:20px 28px 26px;">
        <p style="margin:0 0 8px;font-size:12px;line-height:20px;color:${MUTED};">${
      esc(why)
    }</p>
        <p style="margin:0 0 8px;font-size:12px;line-height:20px;color:${MUTED};">${footerLinks}</p>
        <p style="margin:0;font-size:12px;line-height:20px;color:${MUTED};">${
      esc(s.footerLegal)
    } <a href="${esc(site)}" style="color:${MUTED};">${
      esc(site.replace(/^https?:\/\//, ""))
    }</a></p>
      </td></tr>
    </table>
  </td></tr>
</table>
</body>
</html>`;

  const text = [
    input.heading,
    "",
    ...(input.intro ?? []),
    ...(input.bodyText ? ["", input.bodyText] : []),
    ...(cta ? ["", `${cta.label}: ${cta.url}`] : []),
    "",
    "—",
    why,
    prefs ? `${s.managePrefs}: ${prefs}` : "",
    unsub ? `${s.unsubscribe}: ${unsub}` : "",
    `${s.footerLegal} ${site}`,
  ].filter((line) => line !== "").join("\n");

  return { html, text };
}

// ---------------------------------------------------------------------------
// Templates
// ---------------------------------------------------------------------------

export interface WelcomeInput {
  name?: string | null;
  role?: string | null;
  /** True when the mail follows an address confirmation. */
  confirmed?: boolean;
}

/** Sent once per account: right after signup, or right after the address is
 *  confirmed when confirmations are on. */
export function welcomeEmail(
  locale: Loc,
  input: WelcomeInput,
  links: EmailLinks,
): EmailContent {
  const s = COPY[locale];
  const employer = input.role === "employer";
  const name = (input.name ?? "").trim().split(/\s+/)[0];
  const heading = name
    ? fill(s.greeting, { name })
    : s.greetingPlain;
  const intro = [
    ...(input.confirmed ? [s.welcomeConfirmed] : []),
    employer ? s.welcomeEmployerIntro : s.welcomeSeekerIntro,
  ];
  // The alerts promise is the whole reason a seeker comes back, so it closes
  // the mail right under the steps.
  const outro = employer ? [] : [s.welcomeAlertsHint];
  const steps = employer ? s.welcomeEmployerSteps : s.welcomeSeekerSteps;
  const stepsHtml =
    `<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="margin:6px 0 2px;">` +
    steps
      .map(
        (step, i) =>
          `<tr>
             <td width="28" valign="top" style="padding:6px 0;">
               <span style="display:inline-block;width:22px;height:22px;border-radius:11px;background:${VOLT};color:${INK};font-size:12px;font-weight:800;text-align:center;line-height:22px;">${
            i + 1
          }</span>
             </td>
             <td style="padding:6px 0;font-size:16px;line-height:24px;color:${INK};">${
            esc(step)
          }</td>
           </tr>`,
      )
      .join("") +
    `</table>`;

  const ctaUrl = employer
    ? `${links.site}/${locale}/employer/jobs/new`
    : `${links.site}/${locale}/jobs`;

  const { html, text } = layout({
    loc: locale,
    preheader: employer ? s.welcomeEmployerIntro : s.welcomeSeekerIntro,
    heading,
    intro,
    bodyHtml: stepsHtml + outroHtml(outro),
    bodyText: [
      steps.map((step, i) => `${i + 1}. ${step}`).join("\n"),
      ...outro,
    ].join("\n\n"),
    cta: {
      label: employer ? s.welcomeEmployerCta : s.welcomeSeekerCta,
      url: ctaUrl,
    },
    why: "account",
    links,
  });

  return { subject: s.welcomeSubject, html, text };
}

/** Paragraphs rendered below a body block (same type scale as the intro). */
function outroHtml(paragraphs: string[]): string {
  return paragraphs
    .map(
      (p) =>
        `<p style="margin:16px 0 0;font-size:16px;line-height:26px;color:${INK};">${
          esc(p)
        }</p>`,
    )
    .join("");
}

/**
 * The one-line "why you're seeing this job" caption: the saved search's own
 * name, or the followed company. Rendered on the card and collected into the
 * digest's intro line.
 */
export function alertReason(
  locale: Loc,
  source: string | null | undefined,
  name: string | null | undefined,
): string | null {
  const label = (name ?? "").trim();
  if (!label) return null;
  const s = COPY[locale];
  if (source === "company_follow") return fill(s.alertReasonCompany, { name: label });
  return fill(s.alertReasonSearch, { name: label });
}

export interface JobAlertInput {
  jobs: JobItem[];
  /** Saved-search names / followed company names this run matched. */
  reasons?: string[];
  /** Total matches when more than the listed ones exist. */
  total?: number;
}

/** One digest per person per alert run — never one email per vacancy. */
export function jobAlertEmail(
  locale: Loc,
  input: JobAlertInput,
  links: EmailLinks,
): EmailContent {
  const s = COPY[locale];
  const jobs = input.jobs.slice(0, 8);
  const total = input.total ?? input.jobs.length;
  const heading = alertHeading(locale, total);
  const reasons = (input.reasons ?? []).filter(Boolean).slice(0, 4);
  const intro = reasons.length
    ? [fill(s.alertIntro, { reasons: reasons.join(", ") })]
    : [];

  const cardsHtml = jobs
    .map((job) => {
      const meta = [job.company, job.city].filter(Boolean).join(" · ");
      const url = job.id
        ? `${links.site}/${locale}/jobs/${encodeURIComponent(job.id)}`
        : null;
      const title = url
        ? `<a href="${esc(url)}" style="color:${INK};text-decoration:none;">${
          esc(job.title)
        }</a>`
        : esc(job.title);
      return `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:0 0 12px;border:1px solid ${BORDER};border-radius:14px;">
        <tr><td style="padding:16px 18px;">
          <div style="font-size:17px;line-height:24px;font-weight:700;color:${INK};">${title}</div>
          ${
        meta
          ? `<div style="font-size:14px;line-height:22px;color:${MUTED};padding-top:4px;">${
            esc(meta)
          }</div>`
          : ""
      }
          ${
        job.reason
          ? `<div style="font-size:12px;line-height:20px;color:${MUTED};padding-top:6px;">${
            esc(job.reason)
          }</div>`
          : ""
      }
          ${
        url
          ? `<div style="padding-top:10px;"><a href="${
            esc(url)
          }" style="font-size:14px;font-weight:700;color:${INK};text-decoration:underline;">${
            esc(s.alertViewJob)
          }</a></div>`
          : ""
      }
        </td></tr>
      </table>`;
    })
    .join("");

  const cardsText = jobs
    .map((job) => {
      const meta = [job.company, job.city].filter(Boolean).join(" · ");
      const url = job.id
        ? `${links.site}/${locale}/jobs/${encodeURIComponent(job.id)}`
        : "";
      return [`• ${job.title}`, meta, url].filter(Boolean).join("\n  ");
    })
    .join("\n");

  const { html, text } = layout({
    loc: locale,
    preheader: jobs.map((j) => j.title).join(" · ").slice(0, 120),
    heading,
    intro,
    bodyHtml: cardsHtml,
    bodyText: cardsText,
    cta: { label: s.alertCta, url: `${links.site}/${locale}/jobs` },
    why: "alert",
    unsubscribeScope: "job_match",
    links,
  });

  return { subject: alertSubject(locale, total), html, text };
}

/** Notification types that can travel by email, and how they're framed. */
export type NotificationEmailKind =
  | "message"
  | "application_update"
  | "invite"
  | "review"
  | "marketing";

export interface NotificationEmailInput {
  /** The stored notification row's fields. */
  type: string;
  title: string;
  body: string;
  data: Record<string, unknown>;
  invite?: InviteJob | null;
  /** Deep link into the web app (absolute). */
  url?: string | null;
}

const KIND_SCOPE: Record<NotificationEmailKind, string> = {
  message: "messages",
  application_update: "application",
  invite: "job_match",
  review: "reviews",
  marketing: "marketing",
};

/**
 * Wraps a notification in the branded layout. The title/body come from the
 * same localizer Telegram and push use, so one notification reads identically
 * on every channel — the email just adds a subject, a CTA and a footer.
 */
export function notificationEmail(
  locale: Loc,
  kind: NotificationEmailKind,
  input: NotificationEmailInput,
  links: EmailLinks,
): EmailContent {
  const s = COPY[locale];
  const text = localizedNotificationText(
    locale,
    input.type,
    input.title,
    input.body,
    input.data,
    input.invite,
  );

  const subject = kind === "message"
    ? s.messageSubject
    : kind === "application_update"
    ? s.applicationSubject
    : kind === "invite"
    ? s.inviteSubject
    : text.title || s.openApp;

  const ctaLabel = kind === "message"
    ? s.messageCta
    : kind === "application_update"
    ? s.applicationCta
    : kind === "invite"
    ? s.inviteCta
    : kind === "review"
    ? s.reviewCta
    : s.marketingCta;

  const intro = [text.body].filter((v): v is string => Boolean(v && v.trim()));

  const rendered = layout({
    loc: locale,
    preheader: text.body || text.title,
    heading: text.title,
    intro,
    cta: {
      label: ctaLabel,
      url: safeUrl(input.url) ?? `${links.site}/${locale}`,
    },
    why: kind === "marketing" ? "marketing" : "account",
    unsubscribeScope: KIND_SCOPE[kind],
    links,
  });

  return { subject, html: rendered.html, text: rendered.text };
}
