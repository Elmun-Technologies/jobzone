"use client";

import { MessageCircle } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { useTransition } from "react";

import { buttonVariants } from "@/components/ui/button";
import { startConversationWith } from "@/lib/actions/chat";
import { cn } from "@/lib/utils";

/** Opens (or creates) a direct conversation with the given user. */
export function MessageButton({ profileId }: { profileId: string }) {
  const t = useTranslations("chat");
  const locale = useLocale();
  const [pending, startTransition] = useTransition();

  return (
    <button
      type="button"
      disabled={pending}
      onClick={() =>
        startTransition(() => startConversationWith(profileId, locale))
      }
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
