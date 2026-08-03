"use client";

import { useTranslations } from "next-intl";

import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

/**
 * Localized 404 for not-found resources within a locale (e.g. a missing job).
 *
 * Client component for the same reason as `loading.tsx`: this boundary gets no
 * params of its own, so resolving the locale on the server means reading
 * `headers()` — and every route carries this boundary, so that one read forced
 * the whole app to render per request.
 */
export default function NotFound() {
  const t = useTranslations("common");
  return (
    <Container className="flex flex-col items-center gap-4 py-24 text-center">
      <p className="text-primary text-5xl font-bold">404</p>
      <p className="text-foreground text-lg font-semibold">{t("notFound")}</p>
      <Link
        href="/"
        className={cn(buttonVariants({ variant: "primary", size: "md" }))}
      >
        {t("goHome")}
      </Link>
    </Container>
  );
}
