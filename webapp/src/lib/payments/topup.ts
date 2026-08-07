/**
 * Wallet top-up amount rules, shared by the form (which enables the pay
 * buttons) and the server action (which refuses anything else). The bounds
 * mirror `create_topup_order` (migration 0085) — the database is the real
 * gate, and these keep the UI from offering a payment the RPC would reject.
 *
 * Pure so both sides can rely on the same answer without a round-trip.
 */

/** Below this the gateway fee eats the top-up. */
export const MIN_TOPUP_UZS = 5_000;
/** Matches the RPC's per-transaction ceiling. */
export const MAX_TOPUP_UZS = 50_000_000;

/** Digits typed by a human ("50 000", "50000") → a number, or NaN. */
export function parseTopUpAmount(raw: unknown): number {
  const digits = String(raw ?? "").replace(/[\s ]/g, "");
  if (!/^\d+$/.test(digits)) return Number.NaN;
  return Number(digits);
}

/** Whether this amount can be sent to the gateway as-is. */
export function isValidTopUpAmount(amount: number): boolean {
  return (
    Number.isFinite(amount) &&
    Number.isInteger(amount) &&
    amount >= MIN_TOPUP_UZS &&
    amount <= MAX_TOPUP_UZS
  );
}
