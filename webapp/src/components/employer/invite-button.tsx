"use client";

import { Check, Loader2, UserPlus } from "lucide-react";
import { useTranslations } from "next-intl";
import { useState, useTransition } from "react";

import { buttonVariants } from "@/components/ui/button";
import { inviteCandidate } from "@/lib/actions/invite";
import { cn } from "@/lib/utils";

/** Invites a recommended candidate to the job; flips to a ✓ once notified. */
export function InviteButton({
  jobId,
  candidateId,
}: {
  jobId: string;
  candidateId: string;
}) {
  const t = useTranslations("employer");
  const [pending, start] = useTransition();
  const [invited, setInvited] = useState(false);

  if (invited) {
    return (
      <span
        className={cn(
          buttonVariants({ variant: "outline", size: "sm" }),
          "cursor-default gap-1.5",
        )}
      >
        <Check className="size-4" /> {t("invited")}
      </span>
    );
  }

  return (
    <button
      type="button"
      disabled={pending}
      onClick={() =>
        start(async () => {
          const res = await inviteCandidate(jobId, candidateId);
          if (res.ok) setInvited(true);
        })
      }
      className={cn(buttonVariants({ variant: "primary", size: "sm" }), "gap-1.5")}
    >
      {pending ? (
        <Loader2 className="size-4 animate-spin" />
      ) : (
        <UserPlus className="size-4" />
      )}
      {t("invite")}
    </button>
  );
}
