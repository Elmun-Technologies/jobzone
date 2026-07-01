import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { NotificationRow } from "@/components/account/notification-row";
import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { EmptyState } from "@/components/ui/states";
import { markAllNotificationsRead } from "@/lib/actions/notifications";
import {
  getNotifications,
  type WebNotification,
} from "@/lib/data/notifications";
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

/** Where a notification leads: job_match deep-links to the vacancy. */
function hrefFor(n: WebNotification): string | null {
  const str = (k: string): string | null => {
    const v = n.data[k];
    return typeof v === "string" && v ? v : null;
  };
  switch (n.kind) {
    case "job_match": {
      const id = str("job_id");
      return id ? `/jobs/${id}` : null;
    }
    case "message": {
      const id = str("conversation_id");
      return id ? `/account/messages/${id}` : "/account/messages";
    }
    case "application_update":
      return "/account/applications";
    default:
      return null;
  }
}

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
            {items.map((n) => (
              <NotificationRow
                key={n.id}
                id={n.id}
                kind={n.kind}
                title={n.title}
                body={n.body}
                meta={
                  n.createdAt
                    ? `${formatDate(n.createdAt)} · ${tashkentClock(n.createdAt)}`
                    : ""
                }
                unread={!n.isRead}
                href={hrefFor(n)}
              />
            ))}
          </ul>
        )}
      </div>
    </Container>
  );
}
