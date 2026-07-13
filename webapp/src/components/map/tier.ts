/** The listing tier of a job for the map ('brand' | 'premium'), or null.
 * Legacy boosts map to the nearest tier (featured → brand, top → premium).
 * Shared by both map engines (Leaflet + Yandex) so neither pulls the other's
 * heavy deps just for this. */
export function mapTier(
  boostKind: string | null,
): "brand" | "premium" | null {
  if (boostKind === "premium" || boostKind === "top") return "premium";
  if (boostKind === "brand" || boostKind === "featured") return "brand";
  return null;
}
