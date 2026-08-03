import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { UnsubscribeForm } from "@/components/account/unsubscribe-form";
import { Container } from "@/components/ui/container";
import { getEmailPrefsByToken } from "@/lib/data/notification-settings";
import { isUnsubscribeToken, parseScope } from "@/lib/email-scopes";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "unsubscribe" });
  return { title: t("title"), robots: { index: false, follow: false } };
}

// The token comes from the query string and the page reads live preferences,
// so there is nothing to prerender.
export const dynamic = "force-dynamic";

/**
 * Public unsubscribe landing page. Reachable signed-out — the uuid token in
 * the link is the authorization (migration 0084) — and deliberately read-only
 * until the visitor presses the button: mail scanners follow links, so a GET
 * that opted people out would silently unsubscribe half the recipients of
 * every send.
 */
export default async function UnsubscribePage({
  params,
  searchParams,
}: {
  params: Promise<{ locale: string }>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  const sp = await searchParams;
  const t = await getTranslations("unsubscribe");

  const raw = Array.isArray(sp.token) ? sp.token[0] : sp.token;
  const token = (raw ?? "").trim();
  const scope = parseScope(Array.isArray(sp.scope) ? sp.scope[0] : sp.scope);
  const valid = isUnsubscribeToken(token);
  const prefs = valid ? await getEmailPrefsByToken(token) : null;

  return (
    <Container className="max-w-xl py-14">
      <h1 className="text-foreground text-2xl font-bold">{t("title")}</h1>
      <p className="text-muted-foreground mt-2 text-sm leading-relaxed">
        {t("subtitle")}
      </p>

      {valid ? (
        <UnsubscribeForm
          token={token}
          scope={scope}
          prefs={prefs}
          locale={locale}
        />
      ) : (
        <p className="text-destructive mt-6 text-sm">{t("invalidLink")}</p>
      )}
    </Container>
  );
}
