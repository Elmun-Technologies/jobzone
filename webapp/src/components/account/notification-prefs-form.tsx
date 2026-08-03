"use client";

import { useTranslations } from "next-intl";
import { useActionState } from "react";

import {
  type PrefsFormState,
  updateNotificationPrefs,
} from "@/lib/actions/notification-settings";
import type { NotificationPrefs } from "@/lib/data/notification-settings";

/** One labelled switch. Checkboxes post only when checked, which is exactly
 *  what the action reads — no hidden "off" field needed. */
function Toggle({
  name,
  label,
  hint,
  defaultChecked,
}: {
  name: string;
  label: string;
  hint?: string;
  defaultChecked: boolean;
}) {
  return (
    <label className="border-border flex cursor-pointer items-start gap-3 border-b py-3 last:border-b-0">
      <input
        type="checkbox"
        name={name}
        defaultChecked={defaultChecked}
        className="accent-primary mt-1 size-5 shrink-0 cursor-pointer"
      />
      <span className="min-w-0">
        <span className="text-foreground block text-sm font-medium">
          {label}
        </span>
        {hint ? (
          <span className="text-muted-foreground block text-xs leading-relaxed">
            {hint}
          </span>
        ) : null}
      </span>
    </label>
  );
}

/**
 * Notification preferences: which categories reach the phone (push/Telegram)
 * and which reach the inbox. Both channels are listed together because the
 * user thinks in categories ("job alerts"), not in transports — and because
 * the backend reads them as two independent sets, so turning push off must not
 * look like it silences email too.
 */
export function NotificationPrefsForm({
  locale,
  prefs,
}: {
  locale: string;
  prefs: NotificationPrefs;
}) {
  const t = useTranslations("settings");
  const initial: PrefsFormState = {};
  const [state, action, pending] = useActionState(
    updateNotificationPrefs,
    initial,
  );

  return (
    <form action={action} className="mt-4">
      <input type="hidden" name="locale" value={locale} />

      <h3 className="text-muted-foreground text-xs font-semibold tracking-wide uppercase">
        {t("notifPushGroup")}
      </h3>
      <div className="mt-1">
        <Toggle
          name="push_job_match"
          label={t("notifJobMatch")}
          hint={t("notifJobMatchHint")}
          defaultChecked={prefs.push_job_match}
        />
        <Toggle
          name="push_application"
          label={t("notifApplication")}
          defaultChecked={prefs.push_application}
        />
        <Toggle
          name="push_messages"
          label={t("notifMessages")}
          defaultChecked={prefs.push_messages}
        />
        <Toggle
          name="push_reviews"
          label={t("notifReviews")}
          defaultChecked={prefs.push_reviews}
        />
      </div>

      <h3 className="text-muted-foreground mt-6 text-xs font-semibold tracking-wide uppercase">
        {t("notifEmailGroup")}
      </h3>
      <div className="mt-1">
        <Toggle
          name="email_job_match"
          label={t("emailJobMatch")}
          hint={t("emailJobMatchHint")}
          defaultChecked={prefs.email_job_match}
        />
        <Toggle
          name="email_application"
          label={t("emailApplication")}
          defaultChecked={prefs.email_application}
        />
        <Toggle
          name="email_messages"
          label={t("emailMessages")}
          defaultChecked={prefs.email_messages}
        />
        <Toggle
          name="email_reviews"
          label={t("emailReviews")}
          defaultChecked={prefs.email_reviews}
        />
        <Toggle
          name="email_marketing"
          label={t("emailMarketing")}
          hint={t("emailMarketingHint")}
          defaultChecked={prefs.email_marketing}
        />
      </div>

      <div className="mt-5 flex items-center gap-3">
        <button
          type="submit"
          disabled={pending}
          className="bg-primary text-primary-foreground rounded-lg px-4 py-2 text-sm font-semibold disabled:opacity-50"
        >
          {pending ? t("notifSaving") : t("notifSave")}
        </button>
        {state.ok ? (
          <span className="text-muted-foreground text-sm" role="status">
            {t("notifSaved")}
          </span>
        ) : null}
        {state.error ? (
          <span className="text-destructive text-sm" role="alert">
            {state.error === "signed_out"
              ? t("deleteErrSession")
              : t("deleteErrUnknown")}
          </span>
        ) : null}
      </div>
    </form>
  );
}
