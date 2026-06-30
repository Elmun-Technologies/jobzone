import { getTranslations } from "next-intl/server";

import { Container } from "@/components/ui/container";

export async function SiteFooter() {
  const t = await getTranslations("footer");
  const year = new Date().getFullYear();

  return (
    <footer className="border-border border-t py-8">
      <Container className="text-muted-foreground flex flex-col items-center justify-between gap-2 text-sm sm:flex-row">
        <p>
          <span className="text-foreground font-semibold">Yolla</span> —{" "}
          {t("tagline")}
        </p>
        <p>
          © {year} Yolla. {t("rights")}
        </p>
      </Container>
    </footer>
  );
}
