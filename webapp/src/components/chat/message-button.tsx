"use client";

import { MessageCircle } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { useTransition } from "react";

import { buttonVariants } from "@/components/ui/button";
import { toast } from "@/components/ui/toast";
import { startConversationWith } from "@/lib/actions/chat";
import { useRouter } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

/** Opens (or creates) a direct conversation with the given user. */
export function MessageButton({ profileId }: { profileId: string }) {
  const t = useTranslations("chat");
  const locale = useLocale();
  const router = useRouter();
  const [pending, startTransition] = useTransition();

  function onClick() {
    startTransition(async () => {
      const res = await startConversationWith(profileId);
      if (res.signedOut) {
        // Hard navigation (not the client router), matching bookmark/dismiss:
        // a clean reload re-checks auth state instead of trusting stale
        // client state through the sign-in round trip.
        const next = encodeURIComponent(window.location.pathname);
        window.location.href = `/${locale}/sign-in?next=${next}`;
      } else if (res.ok && res.conversationId) {
        router.push(`/account/messages/${res.conversationId}`);
      } else {
        toast({ title: t("startFailed"), variant: "error" });
      }
    });
  }

  return (
    <button
      type="button"
      disabled={pending}
      onClick={onClick}
      className={cn(
        buttonVariants({ variant: "outline", size: "sm" }),
        "gap-1.5",
      )}
    >
      <MessageCircle className="size-4" />
      {t("message")}
    </button>
  );
}
