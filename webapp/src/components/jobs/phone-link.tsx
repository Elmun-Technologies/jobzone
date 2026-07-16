"use client";

import { Phone } from "lucide-react";

import { track } from "@/lib/analytics/track";

/**
 * Contact-phone `tel:` link with a client-side `phone_click` funnel event.
 * Wraps the anchor rather than the tel handler itself: we want the OS to
 * dispatch normally (no preventDefault) and the track() call to fire
 * on the tap, whether the OS ends up opening a dialer or not.
 */
export function PhoneLink({
  phone,
  jobId,
  companyId,
}: {
  phone: string;
  jobId: string;
  companyId: string;
}) {
  return (
    <a
      href={`tel:${phone.replace(/\s+/g, "")}`}
      onClick={() =>
        track("phone_click", { job_id: jobId, company_id: companyId })
      }
      className="border-border text-foreground hover:border-primary/40 mt-3 flex items-center justify-center gap-2 rounded-full border py-2.5 text-sm font-semibold transition-colors"
    >
      <Phone className="size-4" />
      {phone}
    </a>
  );
}
