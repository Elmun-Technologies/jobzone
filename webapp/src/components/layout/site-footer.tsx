import { getTranslations } from "next-intl/server";

import { Container } from "@/components/ui/container";
import { Link } from "@/i18n/navigation";

import { YollaLogo } from "./yolla-logo";

export async function SiteFooter() {
  const t = await getTranslations("footer");
  const tn = await getTranslations("nav");
  const year = new Date().getFullYear();

  return (
    <footer className="border-border border-t py-8">
      <Container className="text-muted-foreground flex flex-col items-center justify-between gap-3 text-sm sm:flex-row">
        <div className="flex items-center gap-2">
          <YollaLogo />
          <span>— {t("tagline")}</span>
        </div>
        <nav className="flex flex-wrap items-center justify-center gap-x-4 gap-y-2">
          <Link href="/about" className="hover:text-primary transition-colors">
            {tn("about")}
          </Link>
          <Link href="/jobs" className="hover:text-primary transition-colors">
            {tn("jobs")}
          </Link>
          <Link
            href="/companies"
            className="hover:text-primary transition-colors"
          >
            {tn("companies")}
          </Link>
          <Link
            href="/privacy"
            className="hover:text-primary transition-colors"
          >
            {t("privacy")}
          </Link>
          <Link href="/terms" className="hover:text-primary transition-colors">
            {t("terms")}
          </Link>
        </nav>
        <p>
          © {year} Yolla. {t("rights")}
        </p>
      </Container>
    </footer>
  );
}
