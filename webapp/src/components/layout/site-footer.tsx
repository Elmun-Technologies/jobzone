import { getTranslations } from "next-intl/server";

import { Container } from "@/components/ui/container";

import { YollaLogo } from "./yolla-logo";

export async function SiteFooter() {
  const t = await getTranslations("footer");
  const year = new Date().getFullYear();

  return (
    <footer className="border-border border-t py-8">
      <Container className="text-muted-foreground flex flex-col items-center justify-between gap-3 text-sm sm:flex-row">
        <div className="flex items-center gap-2">
          <YollaLogo />
          <span>— {t("tagline")}</span>
        </div>
        <p>
          © {year} Yolla. {t("rights")}
        </p>
      </Container>
    </footer>
  );
}
