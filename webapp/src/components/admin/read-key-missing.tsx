import { EmptyState } from "@/components/ui/states";
import { adminStrings } from "@/lib/admin/strings";

/** Shown when a server-only admin read returns null — SUPABASE_SERVICE_ROLE_KEY
 * isn't configured, so the page has nothing to render. */
export function ReadKeyMissing() {
  return (
    <EmptyState
      title={adminStrings.readKeyMissing}
      description={adminStrings.readKeyMissingHint}
    />
  );
}
