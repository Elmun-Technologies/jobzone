"use client";

import { useTranslations } from "next-intl";

import { Spinner } from "@/components/ui/states";

/**
 * Route-level loading fallback for the locale subtree.
 *
 * A client component on purpose. `loading.tsx` receives no props, so a server
 * version has no locale to work from and next-intl falls back to reading it
 * out of `headers()` — and because this boundary is part of every route's
 * component tree, that single read marked *every* page in the app as
 * dynamic. The locale is already in React context here
 * (NextIntlClientProvider, in the layout above), so the hook costs nothing and
 * leaves the routes prerenderable.
 */
export default function Loading() {
  const t = useTranslations("common");
  return <Spinner label={t("loading")} />;
}
