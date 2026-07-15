/**
 * Runtime check that returns true for logo URLs we should NOT render as an
 * image — either missing or a known-placeholder host.
 *
 * `picsum.photos` is the biggest reason this exists: the seed data
 * (supabase/seed_prod.sql) fills every demo company's `logo_url` with a
 * `picsum.photos/seed/…` URL. In production those pictures are 200×200
 * random photos on an external, slow host — the first company logo on
 * `/jobs` was showing up as the LCP element and stalling for tens of
 * seconds. Treat them as no-logo so the initial-letter avatar renders
 * instead (immediate paint, no network).
 *
 * The helper is deliberately allowlist-shaped: only picsum is
 * downgraded. Real Supabase Storage logos and every other CDN keep
 * rendering as-is.
 */
const PLACEHOLDER_HOSTS = new Set(["picsum.photos"]);

export function isPlaceholderLogo(url: string | null | undefined): boolean {
  if (!url) return true;
  try {
    return PLACEHOLDER_HOSTS.has(new URL(url).hostname);
  } catch {
    // Malformed URL — treat as placeholder so we fall back to the
    // initial avatar rather than passing garbage to <Image>.
    return true;
  }
}

/**
 * Convenience: returns the URL only when it's usable (drops placeholders).
 * Lets callers write `logoUrl(company.logoUrl) ?? <Fallback/>` cleanly.
 */
export function usableLogoUrl(
  url: string | null | undefined,
): string | null {
  return isPlaceholderLogo(url) ? null : (url ?? null);
}
