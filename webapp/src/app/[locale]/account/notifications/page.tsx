import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { NotificationRow } from "@/components/account/notification-row";
import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { EmptyState } from "@/components/ui/states";
import { markAllNotificationsRead } from "@/lib/actions/notifications";
import { getNotifications } from "@/lib/data/notifications";
import {
  inviteParts,
  isJobClosed,
  notificationHref,
  notificationStatus,
  notificationTitleKey,
} from "@/lib/notifications";
import { getCurrentUser } from "@/lib/auth/user";
import { formatDate, tashkentClock } from "@/lib/format";
import { cn } from "@/lib/utils";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "notifications" });
  return { title: t("title"), robots: { index: false } };
}

// Auth-gated, per-user page. Render per request — getCurrentUser()'s try/catch
// swallows the cookies() dynamic signal, so without this Next.js would bake a
// build-time redirect into static HTML (see #142).
export const dynamic = "force-dynamic";

export default async function NotificationsPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);

  // Proxy gates /account; this is the secure (DAL-style) check.
  const user = await getCurrentUser();
  if (!user)
    redirect(`/${locale}/sign-in?next=/${locale}/account/notifications`);

  const t = await getTranslations("notifications");
  // Status labels live with the applications UI; the notification body reuses
  // them so a row and the list it links to never name a status two ways.
  const ts = await getTranslations("applications.status");
  const items = await getNotifications();
  const unread = items.filter((n) => !n.isRead).length;

  return (
    <Container className="max-w-2xl py-10">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h1 className="text-foreground text-2xl font-bold">{t("title")}</h1>
          <p className="text-muted-foreground mt-1 text-sm">{t("subtitle")}</p>
        </div>
        {unread > 0 ? (
          <form action={markAllNotificationsRead.bind(null, locale)}>
            <button
              type="submit"
              className={cn(buttonVariants({ variant: "outline", size: "sm" }))}
            >
              {t("markAllRead")}
            </button>
          </form>
        ) : null}
      </div>

      <div className="mt-6">
        {items.length === 0 ? (
          <EmptyState title={t("emptyTitle")} description={t("emptyBody")} />
        ) : (
          <ul className="border-border divide-border bg-card divide-y overflow-hidden rounded-2xl border">
            {items.map((n) => {
              // The DB stores a fixed-language title for the trigger-raised
              // types; only content-bearing rows keep what the server wrote.
              const titleKey = notificationTitleKey(n.kind, n.data);
              const status = notificationStatus(n.kind, n.data);
              // 0078 stores the vacancy's title as the body; the sentence
              // around it is written here, in the reader's language.
              const closed = isJobClosed(n.data);
              // 0079 carries the company and role, so the invitation reads in
              // the seeker's language rather than the one 0050 wrote it in.
              const invite = inviteParts(n.kind, n.data);
              return (
                <NotificationRow
                  key={n.id}
                  id={n.id}
                  kind={n.kind}
                  title={titleKey ? t(titleKey) : n.title}
                  body={
                    closed
                      ? t("bodyJobClosed", { title: n.body ?? "" })
                      : invite
                        ? t("bodyJobInvite", invite)
                        : status
                          ? t("bodyApplicationUpdate", { status: ts(status) })
                          : n.body
                  }
                  meta={
                    n.createdAt
                      ? `${formatDate(n.createdAt)} · ${tashkentClock(n.createdAt)}`
                      : ""
                  }
                  unread={!n.isRead}
                  href={notificationHref(n.kind, n.data)}
                />
              );
            })}
          </ul>
        )}
      </div>
    </Container>
  );
}
