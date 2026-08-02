import { getCurrentUser } from "@/lib/auth/user";
import { getMyRole } from "@/lib/data/employer";

import { MobileTabBar } from "./mobile-tab-bar";

/**
 * Server half of the phone bottom bar: resolves who is looking (guest, seeker,
 * employer) and hands the client component the two flags it needs.
 *
 * Mounted from the layout rather than from `SiteHeader`, because the header is
 * `sticky` with `backdrop-blur` — that creates a containing block, and a
 * `fixed` child of it is positioned against the 64px header instead of the
 * viewport (the same trap that made the drawer portal to `<body>`).
 */
export async function SiteTabBar() {
  const user = await getCurrentUser();
  // Memoized per request (see getMyRole) — the header asks for this too.
  const role = user ? await getMyRole() : null;
  return (
    <MobileTabBar signedIn={!!user} isEmployerAccount={role === "employer"} />
  );
}
