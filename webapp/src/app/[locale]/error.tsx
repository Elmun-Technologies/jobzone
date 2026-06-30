"use client";

import { useTranslations } from "next-intl";

import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { cn } from "@/lib/utils";

/** Error boundary for the locale subtree. */
export default function Error({ reset }: { error: Error; reset: () => void }) {
  const t = useTranslations("common");
  return (
    <Container className="flex flex-col items-center gap-4 py-24 text-center">
      <p className="text-foreground text-lg font-semibold">{t("error")}</p>
      <button
        type="button"
        onClick={reset}
        className={cn(buttonVariants({ variant: "primary", size: "md" }))}
      >
        {t("retry")}
      </button>
    </Container>
  );
}
