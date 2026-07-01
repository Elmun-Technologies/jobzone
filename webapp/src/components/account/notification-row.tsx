"use client";

import {
  Bell,
  Briefcase,
  FileText,
  MessageCircle,
  Star,
  type LucideIcon,
} from "lucide-react";
import { useLocale } from "next-intl";

import { markNotificationRead } from "@/lib/actions/notifications";
import type { NotificationKind } from "@/lib/data/notifications";
import { useRouter } from "@/i18n/navigation";

const ICONS: Record<NotificationKind, LucideIcon> = {
  job_match: Briefcase,
  message: MessageCircle,
  application_update: FileText,
  review: Star,
  system: Bell,
};

/**
 * One notification. Clicking marks it read (fire-and-forget) and deep-links to
 * its destination — a job_match opens the matching vacancy, completing the
 * saved-search alert loop on the web.
 */
export function NotificationRow({
  id,
  kind,
  title,
  body,
  meta,
  unread,
  href,
}: {
  id: string;
  kind: NotificationKind;
  title: string;
  body: string | null;
  /** Preformatted, hydration-safe timestamp ("01.07.2026 · 18:29"). */
  meta: string;
  unread: boolean;
  /** Locale-relative destination ("/jobs/…"), or null for informational rows. */
  href: string | null;
}) {
  const router = useRouter();
  const locale = useLocale();
  const Icon = ICONS[kind];

  function open() {
    if (unread) void markNotificationRead(id, locale);
    if (href) {
      router.push(href);
    } else if (unread) {
      router.refresh();
    }
  }

  return (
    <li>
      <button
        type="button"
        onClick={open}
        className="hover:bg-muted/50 flex w-full items-start gap-3 p-4 text-left transition-colors"
      >
        <span
          className={`mt-0.5 flex size-9 shrink-0 items-center justify-center rounded-full ${
            unread ? "bg-primary/15 text-primary" : "bg-muted text-muted-foreground"
          }`}
        >
          <Icon className="size-4" />
        </span>
        <span className="min-w-0 flex-1">
          <span className="flex items-baseline justify-between gap-3">
            <span
              className={`text-foreground block truncate text-sm ${
                unread ? "font-semibold" : "font-medium"
              }`}
            >
              {title}
            </span>
            <span className="text-muted-foreground shrink-0 text-xs">
              {meta}
            </span>
          </span>
          {body ? (
            <span className="text-muted-foreground mt-0.5 block truncate text-sm">
              {body}
            </span>
          ) : null}
        </span>
        {unread ? (
          <span
            aria-hidden
            className="bg-primary mt-2 size-2 shrink-0 rounded-full"
          />
        ) : null}
      </button>
    </li>
  );
}
