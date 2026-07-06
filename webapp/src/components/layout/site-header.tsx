import { Bell, CircleUser, FilePlus2 } from "lucide-react";
import { getTranslations } from "next-intl/server";

import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { getCurrentUser } from "@/lib/auth/user";
import { getUnreadNotificationCount } from "@/lib/data/notifications";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

import { LocaleSwitcher } from "./locale-switcher";
import { RoleToggle } from "./role-toggle";
import { ThemeToggle } from "./theme-toggle";
import { YollaLogo } from "./yolla-logo";

const navLink =
  "text-foreground hover:text-primary text-sm font-medium transition-colors";

/** Top navigation: brand + audience toggle, primary links, resume CTA, auth. */
export async function SiteHeader() {
  const t = await getTranslations("nav");
  const user = await getCurrentUser();
  const unread = user ? await getUnreadNotificationCount() : 0;

  return (
    <header className="border-border bg-background/80 sticky top-0 z-50 border-b backdrop-blur">
      <Container className="flex h-16 items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <Link href="/" aria-label="Yolla">
            <YollaLogo />
          </Link>
          <div className="hidden sm:block">
            <RoleToggle />
          </div>
        </div>

        <div className="flex items-center gap-2 sm:gap-4">
          <nav className="hidden items-center gap-5 lg:flex">
            <Link href="/" className={navLink}>
              {t("home")}
            </Link>
            <Link href="/jobs" className={navLink}>
              {t("jobs")}
            </Link>
            <Link href="/companies" className={navLink}>
              {t("companies")}
            </Link>
            <Link href="/about" className={navLink}>
              {t("about")}
            </Link>
            <Link href="/account/bookmarks" className={navLink}>
              {t("saved")}
            </Link>
          </nav>

          <Link
            href="/resumes/new"
            className={cn(
              buttonVariants({ variant: "primary", size: "sm" }),
              "hidden gap-1.5 sm:inline-flex",
            )}
          >
            <FilePlus2 className="size-4" />
            {t("createResume")}
          </Link>

          <LocaleSwitcher />
          <ThemeToggle />

          {user ? (
            <>
              <Link
                href="/account/notifications"
                aria-label={t("notifications")}
                className={cn(
                  buttonVariants({ variant: "outline", size: "sm" }),
                  "relative px-2.5",
                )}
              >
                <Bell className="size-4" />
                {unread > 0 ? (
                  <span className="bg-primary text-primary-foreground absolute -top-1.5 -right-1.5 flex h-4 min-w-4 items-center justify-center rounded-full px-1 text-[10px] font-bold">
                    {unread > 9 ? "9+" : unread}
                  </span>
                ) : null}
              </Link>
              <Link
                href="/account"
                className={cn(
                  buttonVariants({ variant: "outline", size: "sm" }),
                  "gap-1.5",
                )}
              >
                <CircleUser className="size-4" />
                <span className="hidden sm:inline">{t("account")}</span>
              </Link>
            </>
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
