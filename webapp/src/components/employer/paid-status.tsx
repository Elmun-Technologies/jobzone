"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";

/** Payment-confirmation poller. The vacancy is still a draft when the employer
 * lands back from the gateway — the provider callback flips the order to paid
 * (which publishes the job) a moment later, out of band. Re-fetch the server
 * component every few seconds so the page turns into the "published" state on
 * its own, without the employer reloading. */
export function PaidStatusPoller() {
  const router = useRouter();
  useEffect(() => {
    const id = setInterval(() => router.refresh(), 3000);
    return () => clearInterval(id);
  }, [router]);
  return null;
}
