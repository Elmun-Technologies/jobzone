"use client";

import { useTranslations } from "next-intl";
import { useActionState, useState } from "react";

import {
  deleteAccountAction,
  type DeleteAccountFormState,
} from "@/lib/auth/actions";

/**
 * Delete-account form: reason (optional) + typed confirmation phrase.
 * Server action validates the phrase again so the form's `required`
 * attribute is a UX nicety, not the security boundary. The submit button
 * is disabled until the visitor types the exact confirmation phrase — a
 * concrete "yes I mean it" gesture that's harder to click through by
 * accident than a bare confirm dialog.
 */
export function DeleteAccountForm({ locale }: { locale: string }) {
  const t = useTranslations("settings");
  const initial: DeleteAccountFormState = {};
  const [state, action, pending] = useActionState(deleteAccountAction, initial);
  const [confirm, setConfirm] = useState("");
  const canSubmit = confirm.trim().toUpperCase() === "DELETE";

  const errorMsg = state.error
    ? state.error === "confirm"
      ? t("deleteErrConfirm")
      : state.error === "no_session"
        ? t("deleteErrSession")
        : t("deleteErrUnknown")
    : undefined;

  return (
    <form action={action} className="space-y-3">
      <input type="hidden" name="locale" value={locale} />
      <label className="text-foreground block text-sm font-medium">
        {t("deleteReasonLabel")}
        <textarea
          name="reason"
          rows={2}
          placeholder={t("deleteReasonPlaceholder")}
          className="border-border bg-background text-foreground mt-1 block w-full rounded-md border p-2 text-sm"
        />
      </label>
      <label className="text-foreground block text-sm font-medium">
        {t("deleteConfirmLabel")}
        <input
          type="text"
          name="confirm"
          autoComplete="off"
          required
          value={confirm}
          onChange={(e) => setConfirm(e.target.value)}
          placeholder="DELETE"
          className="border-border bg-background text-foreground mt-1 block w-full rounded-md border p-2 text-sm font-mono uppercase"
        />
      </label>
      {errorMsg ? (
        <p className="text-destructive text-sm" role="alert">
          {errorMsg}
        </p>
      ) : null}
      <button
        type="submit"
        disabled={!canSubmit || pending}
        className="bg-destructive text-destructive-foreground rounded-md px-4 py-2 text-sm font-semibold disabled:cursor-not-allowed disabled:opacity-40"
      >
        {pending ? t("deleteInProgress") : t("deleteCta")}
      </button>
    </form>
  );
}
