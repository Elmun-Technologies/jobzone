"use client";

import { useTranslations } from "next-intl";
import { useActionState } from "react";

import {
  applyEmailPrefByToken,
  type UnsubscribeState,
} from "@/lib/actions/notification-settings";
import type { EmailPrefs, EmailScope } from "@/lib/email-scopes";

/**
 * The unsubscribe landing page's form. Nothing happens on load — a GET must
 * never opt someone out, because inbox link-scanners follow every URL in an
 * email. The visitor confirms with one button, and can undo it in place with
 * the same action (p_enabled = true), which is what turns a mis-click into a
 * non-event instead of a support request.
 */
export function UnsubscribeForm({
  token,
  scope,
  prefs,
  locale,
}: {
  token: string;
  scope: EmailScope;
  prefs: EmailPrefs | null;
  locale: string;
}) {
  const t = useTranslations("unsubscribe");
  const initial: UnsubscribeState = {};
  const [state, action, pending] = useActionState(
    applyEmailPrefByToken,
    initial,
  );

  const scopeLabel = t(`scope_${scope}`);

  if (state.error) {
    return (
      <p className="text-destructive mt-6 text-sm" role="alert">
        {state.error === "invalid" ? t("invalidLink") : t("failed")}
      </p>
    );
  }

  // Post-action state: confirm what changed and offer the undo.
  if (state.prefs) {
    const done = state.enabled ? t("resubscribed") : t("done");
    return (
      <div className="mt-6">
        <p className="text-foreground text-base" role="status">
          {done}
        </p>
        <form action={action} className="mt-4 flex flex-wrap gap-3">
          <input type="hidden" name="token" value={token} />
          <input type="hidden" name="scope" value={scope} />
          {state.enabled ? null : (
            <input type="hidden" name="enabled" value="1" />
          )}
          <button
            type="submit"
            disabled={pending}
            className="border-border text-foreground rounded-lg border px-4 py-2 text-sm font-semibold disabled:opacity-50"
          >
            {state.enabled ? t("unsubscribeCta") : t("undoCta")}
          </button>
          <a
            href={`/${locale}/account/settings`}
            className="text-muted-foreground rounded-lg px-4 py-2 text-sm font-semibold underline"
          >
            {t("manageCta")}
          </a>
        </form>
      </div>
    );
  }

  return (
    <form action={action} className="mt-6">
      <input type="hidden" name="token" value={token} />
      <input type="hidden" name="scope" value={scope} />
      <p className="text-foreground text-base">
        {t("confirm", { scope: scopeLabel })}
      </p>
      {prefs ? null : (
        <p className="text-muted-foreground mt-2 text-sm">
          {t("unknownState")}
        </p>
      )}
      <div className="mt-5 flex flex-wrap gap-3">
        <button
          type="submit"
          disabled={pending}
          className="bg-primary text-primary-foreground rounded-lg px-4 py-2 text-sm font-semibold disabled:opacity-50"
        >
          {pending ? t("working") : t("unsubscribeCta")}
        </button>
        <a
          href={`/${locale}/account/settings`}
          className="border-border text-foreground rounded-lg border px-4 py-2 text-sm font-semibold"
        >
          {t("manageCta")}
        </a>
      </div>
    </form>
  );
}
