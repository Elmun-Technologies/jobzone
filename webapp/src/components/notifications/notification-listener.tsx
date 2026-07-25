"use client";

import { useLocale, useTranslations } from "next-intl";
import { useEffect, useMemo } from "react";

import { toast } from "@/components/ui/toast";
import { useRouter } from "@/i18n/navigation";
import { notificationHref, toNotificationKind } from "@/lib/notifications";
import { createClient } from "@/lib/supabase/client";

/**
 * Pops a toast for every notification that lands while the tab is open.
 *
 * `notifications` is already in the `supabase_realtime` publication
 * (0005:102) and RLS confines the stream to the recipient, but the filter is
 * set explicitly anyway: without it the client subscribes to every INSERT and
 * relies on the server dropping the ones it may not see.
 *
 * Rendered from SiteHeader, which already resolved the user — this keeps the
 * subscription out of the layout and off guest pages entirely.
 */
export function NotificationListener({ userId }: { userId: string }) {
  const t = useTranslations("notifications");
  const supabase = useMemo(() => createClient(), []);
  const router = useRouter();
  const locale = useLocale();

  useEffect(() => {
    const channel = supabase
      .channel(`notifications:${userId}`)
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "notifications",
          filter: `recipient_id=eq.${userId}`,
        },
        (payload) => {
          const row = payload.new as Record<string, unknown>;
          const kind = toNotificationKind(row.type);
          const data =
            row.data && typeof row.data === "object"
              ? (row.data as Record<string, unknown>)
              : {};
          // `localePrefix: "always"` — the toast renders a plain anchor, so
          // the prefix has to be added here (Link would do it for us).
          const path = notificationHref(kind, data);
          toast({
            title: String(row.title ?? t("title")),
            description: typeof row.body === "string" ? row.body : null,
            href: path ? `/${locale}${path}` : null,
            actionLabel: t("toastAction"),
          });
          // Repaint the server components so the header bell's unread badge
          // moves with the toast instead of waiting for the next navigation.
          router.refresh();
        },
      )
      .subscribe();
    return () => {
      supabase.removeChannel(channel);
    };
  }, [supabase, userId, router, locale, t]);

  return null;
}
