import { CircleUser } from "lucide-react";
import { getTranslations } from "next-intl/server";

import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { getCurrentUser } from "@/lib/auth/user";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

import { LocaleSwitcher } from "./locale-switcher";
import { ThemeToggle } from "./theme-toggle";

/** Responsive top navigation: brand, primary links, locale + theme, auth. */
export async function SiteHeader() {
  const t = await getTranslations("nav");
  const user = await getCurrentUser();

  return (
    <header className="border-border bg-background/80 sticky top-0 z-50 border-b backdrop-blur">
      <Container className="flex h-16 items-center justify-between gap-4">
        <Link
          href="/"
          className="text-primary text-lg font-bold tracking-tight"
        >
          Jobzone
        </Link>

        <nav className="hidden items-center gap-6 md:flex">
          <Link
            href="/jobs"
            className="text-foreground hover:text-primary text-sm font-medium transition-colors"
          >
            {t("jobs")}
          </Link>
          <Link
            href="/companies"
            className="text-foreground hover:text-primary text-sm font-medium transition-colors"
          >
            {t("companies")}
          </Link>
        </nav>

        <div className="flex items-center gap-2">
          <LocaleSwitcher />
          <ThemeToggle />
          {user ? (
            <Link
              href="/account"
              className={cn(
                buttonVariants({ variant: "outline", size: "sm" }),
                "gap-1.5",
              )}
            >
              <CircleUser className="size-4" />
              {t("account")}
            </Link>
          ) : (
            <Link
              href="/sign-in"
              className={cn(buttonVariants({ variant: "primary", size: "sm" }))}
            >
              {t("signIn")}
            </Link>
          )}
        </div>
      </Container>
    </header>
  );
}
