import "server-only";

import { mockBroadcastCounts } from "../mock";
import { adminReadClient } from "./shared";

/** Audience sizes shown on the broadcast page so the admin sees the reach
 *  before sending. City filter narrows further server-side; these are the
 *  unscoped totals (active, non-suspended profiles). */
export interface BroadcastCounts {
  all: number;
  seekers: number;
  employers: number;
}

export async function getBroadcastCounts(): Promise<BroadcastCounts | null> {
  const client = await adminReadClient();
  if (client === "mock") return mockBroadcastCounts();
  if (!client) return null;
  try {
    const base = () =>
      client
        .from("profiles")
        .select("id", { count: "exact", head: true })
        .is("suspended_at", null);
    const [all, seekers, employers] = await Promise.all([
      base(),
      base().eq("role", "job_seeker"),
      base().eq("role", "employer"),
    ]);
    return {
      all: all.count ?? 0,
      seekers: seekers.count ?? 0,
      employers: employers.count ?? 0,
    };
  } catch (e) {
    console.error("getBroadcastCounts failed", e);
    return { all: 0, seekers: 0, employers: 0 };
  }
}
