"use client";

import { Bell, CircleUser } from "lucide-react";
import dynamic from "next/dynamic";
import { useTranslations } from "next-intl";

import { useSession } from "@/components/auth/session-provider";
import { buttonVariants } from "@/components/ui/button";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

/**
 * Lazy on purpose. The listener opens a Realtime subscription, so it pulls the
 * whole Supabase client in with it — 244 KB that every page in the app was
 * shipping because this component sits in the header, including to the guest
 * arriving from a search result who has no notifications to listen for. As a
 * dynamic import it is fetched by the people it is for.
 */
const NotificationListener = dynamic(
  () =>
    import("@/components/notifications/notification-listener").then(
      (m) => m.NotificationListener,
    ),
  { ssr: false },
);

/**
 * The right-hand end of the header: notifications + account for a signed-in
 * visitor, a sign-in button for everyone else.
 *
 * This is the only part of the header that depends on who is asking, and it
 * asks in the browser (see SessionProvider). That is deliberate: while the
 * server resolved it, every page in the app — including a vacancy a search
 * engine is crawling — had to be rendered per request.
 *
 * While the answer is still unknown it renders a placeholder of exactly the
 * same size as the buttons that will replace it, so the header does not jump
 * and nobody is shown "Sign in" while they are signed in.
 */
export function HeaderAuth() {
  const t = useTranslations("nav");
  const { signedIn, userId, unread } = useSession();

  if (signedIn === null) {
    return (
      <div
        aria-hidden
        className="bg-muted/60 h-8 w-[4.5rem] shrink-0 rounded-md sm:w-28"
      />
    );
  }

  if (!signedIn) {
    return (
      <Link
        href="/sign-in"
        className={cn(buttonVariants({ variant: "primary", size: "sm" }))}
      >
        {t("signIn")}
      </Link>
    );
  }

  return (
    <>
      {/* Renders nothing; subscribes to this user's notifications and pops a
          toast for each one that arrives live. */}
      {userId ? <NotificationListener userId={userId} /> : null}
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
  );
}
