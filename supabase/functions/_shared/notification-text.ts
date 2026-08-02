// notification-text.ts — renders a notification in the recipient's language.
//
// The in-app clients already do this: the notification triggers store a
// fixed-language string (0005 writes the literal English "Application update"
// / "New message"; invite_candidate() in 0050 writes Uzbek), so both the app
// and the web list re-derive the text from `type` + `data` instead of showing
// the column. Anything the backend sends *outward* — Telegram, FCM push — is
// composed here, where there is no client to do that, so it has to happen
// server-side from `profiles.preferred_locale`.
//
// The same content-vs-copy rule the clients use applies: a saved-search
// alert's title is the vacancy's own name and its body is "Company · City",
// which are content and pass through untouched. Only fixed-language copy is
// replaced.

export type Loc = "uz" | "ru" | "en";

const LOCALES: readonly Loc[] = ["uz", "ru", "en"];

/** profiles.preferred_locale → a locale we have strings for. */
export function normalizeLocale(v: unknown): Loc {
  const code = String(v ?? "").slice(0, 2).toLowerCase();
  return (LOCALES as readonly string[]).includes(code) ? (code as Loc) : "uz";
}

const STRINGS: Record<Loc, Record<string, string>> = {
  uz: {
    applicationTitle: "Ariza holati yangilandi",
    applicationBody: "Arizangiz holati: {status}",
    messageTitle: "Yangi xabar",
    inviteTitle: "Ish taklifi",
    inviteBody: '{company} sizni "{title}" lavozimiga taklif qilmoqda.',
    inviteBodyPlain: "Ish beruvchi sizni ishga taklif qilmoqda.",
    submitted: "Yuborilgan",
    viewed: "Ko'rilgan",
    shortlisted: "Qisqa ro'yxatda",
    interview: "Suhbat",
    offer: "Taklif",
    rejected: "Rad etilgan",
    hired: "Ishga olindi",
    withdrawn: "Qaytarib olingan",
  },
  ru: {
    applicationTitle: "Статус отклика обновлён",
    applicationBody: "Статус вашего отклика: {status}",
    messageTitle: "Новое сообщение",
    inviteTitle: "Приглашение на работу",
    inviteBody: '{company} приглашает вас на должность «{title}».',
    inviteBodyPlain: "Работодатель приглашает вас на работу.",
    submitted: "Отправлено",
    viewed: "Просмотрено",
    shortlisted: "В шортлисте",
    interview: "Собеседование",
    offer: "Оффер",
    rejected: "Отклонено",
    hired: "Принят",
    withdrawn: "Отозван",
  },
  en: {
    applicationTitle: "Application update",
    applicationBody: "Your application is now: {status}",
    messageTitle: "New message",
    inviteTitle: "Job invitation",
    inviteBody: '{company} is inviting you to apply for "{title}".',
    inviteBodyPlain: "An employer is inviting you to apply.",
    submitted: "Submitted",
    viewed: "Viewed",
    shortlisted: "Shortlisted",
    interview: "Interview",
    offer: "Offer",
    rejected: "Rejected",
    hired: "Hired",
    withdrawn: "Withdrawn",
  },
};

/** Statuses we have a label for; anything else keeps the stored sentence. */
const STATUSES = new Set([
  "submitted",
  "viewed",
  "shortlisted",
  "interview",
  "offer",
  "rejected",
  "hired",
  "withdrawn",
]);

function fill(template: string, vars: Record<string, string>): string {
  return template.replace(/\{(\w+)\}/g, (m, k) => vars[k] ?? m);
}

export interface NotificationText {
  title: string;
  body: string;
}

/** An invitation's job, when the caller looked it up. */
export interface InviteJob {
  company: string;
  title: string;
}

/**
 * The title/body to send outward, in [locale]. Pure — the caller supplies
 * [invite] because an invitation's stored payload carries only `job_id`, and
 * the DB round-trip belongs with the rest of the querying.
 */
export function localizedNotificationText(
  locale: Loc,
  type: string,
  storedTitle: string,
  storedBody: string,
  data: Record<string, unknown>,
  invite?: InviteJob | null,
): NotificationText {
  const s = STRINGS[locale];

  if (type === "application_update") {
    const status = String(data.status ?? "");
    return {
      title: s.applicationTitle,
      // An unrecognised status (one added after this deploy) keeps the
      // server's own sentence rather than rendering a raw placeholder.
      body: STATUSES.has(status)
        ? fill(s.applicationBody, { status: s[status] })
        : storedBody,
    };
  }

  if (type === "message") {
    // The body is the message preview — the sender's own words.
    return { title: s.messageTitle, body: storedBody };
  }

  if (type === "job_match" && data.invited === true) {
    // Without the lookup, the stored Uzbek sentence beats saying nothing —
    // a failed query must never cost the recipient the notification itself.
    return {
      title: s.inviteTitle,
      body: invite?.company && invite.title
        ? fill(s.inviteBody, { company: invite.company, title: invite.title })
        : storedBody || s.inviteBodyPlain,
    };
  }

  // job_match from a saved-search alert (title = the vacancy's own name,
  // body = "Company · City") and review/system admin copy: content, not copy.
  return { title: storedTitle, body: storedBody };
}
