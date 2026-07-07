// Pure gating logic for the "first vacancy free, then charged" rule — split
// out from the wizard component so it's unit-testable without a DB. The
// server action re-derives the same `willCharge` condition before actually
// debiting the wallet; this is the client-side mirror used to preview it and
// to disable Publish before a doomed submit.

/** Would publishing charge this employer (not their first, and pricing is
 * active)? A `priceUzs` of 0 (e.g. a promo) always means free. */
export function willChargeForJobPost(
  hasPublishedBefore: boolean,
  priceUzs: number,
): boolean {
  return hasPublishedBefore && priceUzs > 0;
}

/** Does the Hamyon balance cover the price? */
export function canAffordJobPost(
  balanceUzs: number,
  priceUzs: number,
): boolean {
  return balanceUzs >= priceUzs;
}
