import { ArrowRight } from "lucide-react";
import { getTranslations } from "next-intl/server";

import { Container } from "@/components/ui/container";
import { Link } from "@/i18n/navigation";

/**
 * Volt "post a vacancy in 3 minutes" banner for the home page — the employer
 * conversion CTA, pulling copy from the shared `landing.employers` namespace.
 */
export async function EmployerCta() {
  const t = await getTranslations("landing");
  return (
    <Container className="py-12 sm:py-16">
      <div className="bg-primary text-primary-foreground rounded-3xl px-6 py-12 text-center sm:px-12">
        <span className="text-primary-foreground/70 font-mono text-xs font-semibold tracking-wider uppercase">
          {t("employers.eyebrow")}
        </span>
        <h2 className="mt-3 text-2xl font-bold tracking-tight text-balance sm:text-3xl">
          {t("employers.title")}
        </h2>
        <p className="text-primary-foreground/80 mx-auto mt-3 max-w-xl text-sm text-pretty">
          {t("employers.body")}
        </p>
        <div className="mt-6 flex flex-col items-center justify-center gap-3 sm:flex-row">
          <Link
            href="/employer/jobs/new"
            className="bg-foreground text-background inline-flex h-11 items-center justify-center gap-2 rounded-full px-6 font-semibold transition-opacity hover:opacity-90"
          >
            {t("employers.cta")}
            <ArrowRight className="size-4" />
          </Link>
          <Link
            href="/about#pricing"
            className="border-primary-foreground/30 hover:bg-primary-foreground/10 inline-flex h-11 items-center justify-center rounded-full border px-6 font-semibold transition-colors"
          >
            {t("pricing.eyebrow")}
          </Link>
        </div>
      </div>
    </Container>
  );
}
