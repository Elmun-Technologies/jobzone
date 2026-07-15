import { getLocale, getTranslations } from "next-intl/server";

import { Spinner } from "@/components/ui/states";

/** Route-level loading fallback for the locale subtree. */
export default async function Loading() {
  const locale = await getLocale();
  const t = await getTranslations({ locale, namespace: "common" });
  return <Spinner label={t("loading")} />;
}
