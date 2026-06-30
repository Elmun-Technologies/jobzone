import { Search } from "lucide-react";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

export default async function HomePage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("home");

  return (
    <Container className="py-20 sm:py-28">
      <div className="mx-auto flex max-w-2xl flex-col items-center gap-6 text-center">
        <h1 className="text-foreground text-4xl font-bold tracking-tight sm:text-5xl">
          {t("heroTitle")}
        </h1>
        <p className="text-muted-foreground text-lg">{t("heroSubtitle")}</p>

        {/* Skeleton search bar — wired to real search in the public-board phase. */}
        <form
          action="/jobs"
          className="border-border bg-card flex w-full max-w-xl items-center gap-2 rounded-full border p-2 shadow-sm"
        >
          <Search className="text-muted-foreground ml-3 size-5 shrink-0" />
          <input
            name="q"
            placeholder={t("searchPlaceholder")}
            className="text-foreground placeholder:text-muted-foreground h-10 flex-1 bg-transparent px-1 outline-none"
          />
          <button
            type="submit"
            className={cn(buttonVariants({ variant: "primary", size: "sm" }))}
          >
            {t("searchCta")}
          </button>
        </form>

        <Link
          href="/jobs"
          className={cn(buttonVariants({ variant: "outline", size: "md" }))}
        >
          {t("browseAll")}
        </Link>
      </div>
    </Container>
  );
}
