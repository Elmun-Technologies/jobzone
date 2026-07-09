import { getSiteBanner } from "@/lib/data/settings";

/**
 * Site-wide announcement/maintenance bar, driven by the admin `site_banner`
 * setting (0057). Renders nothing when disabled/empty/offline. Async server
 * component; the read is cookie-free (see getSiteBanner) so it never forces
 * the shared root layout — and with it the static SEO pages — into dynamic
 * rendering.
 */
export async function SiteBanner() {
  const banner = await getSiteBanner();
  if (!banner) return null;

  const tone =
    banner.tone === "warning"
      ? "bg-amber-100 text-amber-900 dark:bg-amber-900/40 dark:text-amber-100"
      : "bg-primary/15 text-foreground";

  return (
    <div
      role="status"
      className={`px-4 py-2 text-center text-sm font-medium ${tone}`}
    >
      {banner.message}
    </div>
  );
}
