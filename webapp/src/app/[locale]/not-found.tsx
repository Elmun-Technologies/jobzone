import { getTranslations } from "next-intl/server";

import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

/** Localized 404 for not-found resources within a locale (e.g. a missing job). */
export default async function NotFound() {
  const t = await getTranslations("common");
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
