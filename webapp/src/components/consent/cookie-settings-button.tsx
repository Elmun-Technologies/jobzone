"use client";

import { useTranslations } from "next-intl";

import { CONSENT_COOKIE } from "@/lib/consent";

/**
 * Footer "Cookie settings" link — clears the consent cookie so the banner
 * reappears on next paint. Required by GDPR + UZ personal-data law: a
 * visitor who accepted must be able to withdraw with the same ease they
 * accepted with. The full reload picks up the cleared cookie in server
 * layout and unmounts the analytics scripts.
 */
export function CookieSettingsButton({ className }: { className?: string }) {
  const t = useTranslations("consent");
  return (
    <button
      type="button"
      onClick={() => {
        document.cookie = `${CONSENT_COOKIE}=; Path=/; Max-Age=0; SameSite=Lax`;
        try {
          window.localStorage.removeItem(CONSENT_COOKIE);
        } catch {
          // ignore
        }
        window.location.reload();
      }}
      className={className}
    >
      {t("settings")}
    </button>
  );
}
