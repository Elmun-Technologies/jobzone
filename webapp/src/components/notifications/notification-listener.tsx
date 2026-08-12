"use client";

import { useLocale, useTranslations } from "next-intl";
import { useEffect, useMemo, useRef } from "react";

import { useSession } from "@/components/auth/session-provider";
import { toast } from "@/components/ui/toast";
import { useRouter } from "@/i18n/navigation";
import {
  inviteParts,
  isJobClosed,
  notificationHref,
  notificationStatus,
  notificationTitleKey,
  toNotificationKind,
} from "@/lib/notifications";
import { createClient } from "@/lib/supabase/client";

/**
 * Pops a toast for every notification that lands while the tab is open.
 *
 * `notifications` is already in the `supabase_realtime` publication
 * (0005:102) and RLS confines the stream to the recipient, but the filter is
 * set explicitly anyway: without it the client subscribes to every INSERT and
 * relies on the server dropping the ones it may not see.
 *
 * Rendered from the header's auth cluster, which already resolved the user —
 * this keeps the subscription out of the layout and off guest pages entirely.
 */
export function NotificationListener({ userId }: { userId: string }) {
  const t = useTranslations("notifications");
  const ts = useTranslations("applications.status");
  const supabase = useMemo(() => createClient(), []);
  const router = useRouter();
  const locale = useLocale();
  const { refresh } = useSession();
  // At most one reconciliation per mount — see the subscribe callback below.
  // A ref, not state: it must survive the effect re-running without ever
  // letting a re-subscribe turn into a refresh/re-subscribe loop.
  const reconciled = useRef(false);

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
          // Same rule as the list page: the trigger-raised types carry a
          // fixed-language title, so the toast localizes them rather than
          // echoing the column (see notificationTitleKey).
          const titleKey = notificationTitleKey(kind, data);
          const status = notificationStatus(kind, data);
          const closed = isJobClosed(data);
          const invite = inviteParts(kind, data);
          toast({
            title: titleKey ? t(titleKey) : String(row.title ?? t("title")),
            description: closed
              ? t("bodyJobClosed", { title: String(row.body ?? "") })
              : invite
                ? t("bodyJobInvite", invite)
                : status
                  ? t("bodyApplicationUpdate", { status: ts(status) })
                  : typeof row.body === "string"
                    ? row.body
                    : null,
            href: path ? `/${locale}${path}` : null,
            actionLabel: t("toastAction"),
          });
          // Move the header bell's unread badge with the toast instead of
          // waiting for the next navigation — the count lives in the session
          // context now, and router.refresh() repaints any server-rendered
          // list (the notifications page) that is on screen behind it.
          refresh();
          router.refresh();
        },
      )
      .subscribe((status) => {
        // Close the gap between "unread counted" and "listening".
        //
        // The session provider counts unread the moment it resolves the user;
        // this component is only mounted once that has happened, and it is a
        // lazy chunk, so on a slow connection there is a window — a fetch plus
        // a WebSocket handshake wide — in which a notification can land
        // unseen. It gets no toast (it is in the list either way) and, worse,
        // the bell would keep showing a count taken before it arrived. One
        // re-count on connect covers whatever happened in between.
        if (status === "SUBSCRIBED" && !reconciled.current) {
          reconciled.current = true;
          refresh();
        }
      });
    return () => {
      supabase.removeChannel(channel);
    };
  }, [supabase, userId, router, locale, t, ts, refresh]);

  return null;
}
